import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'flashcard_screen.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';
import '../services/review_state.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/tutorial_service.dart';
import '../services/ui_language_provider.dart';
import '../utils/topic_names.dart';
import '../widgets/email_verification_banner.dart';
import 'profile_screen.dart';
import 'review_screen.dart';

class DeckSelectorScreen extends StatefulWidget {
  final List<FlashcardDeck> decks;
  final String baseLanguage;
  final String targetLanguage;
  final bool showTutorial;

  const DeckSelectorScreen({
    super.key,
    required this.decks,
    required this.baseLanguage,
    required this.targetLanguage,
    this.showTutorial = false,
  });

  @override
  State<DeckSelectorScreen> createState() => _DeckSelectorScreenState();
}

class _DeckSelectorScreenState extends State<DeckSelectorScreen> {
  final RepetitionService _repetitionService = RepetitionService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  // Box level stats - global across all topics (excluding box 0 - unseen cards)
  Map<int, int> _globalBoxStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  Map<int, List<Flashcard>> _globalBoxCards = {1: [], 2: [], 3: [], 4: [], 5: []};
  
  // All box stats (including not due cards)
  Map<int, int> _allBoxStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  Map<int, List<Flashcard>> _allBoxCards = {1: [], 2: [], 3: [], 4: [], 5: []};
  
  // Original topic deck stats
  Map<String, Map<String, int>> _deckStats = {};
  
  late ConfettiController _confettiController;

  // Tutorial keys
  final GlobalKey _firstLevelDeckKey = GlobalKey();
  final GlobalKey _firstTopicDeckKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initializeProgressData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _initializeProgressData() async {
    setState(() {
      _isLoading = false; // Show UI immediately
    });

    // Load progress in background without blocking
    _loadProgressInBackground();
  }

  Future<void> _loadProgressInBackground() async {
    try {
      // Collect all cards from all decks
      final allCards = <Flashcard>[];
      for (final deck in widget.decks) {
        allCards.addAll(deck.cards);
      }

      // Load progress data (this happens in background)
      if (!_repetitionService.isCacheLoaded) {
        await _repetitionService.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('Progress initialization timed out - using defaults');
          },
        );
      }

      // Calculate DUE box stats (only cards that are due for review TODAY)
      final dueBoxStats = _repetitionService.getDueBoxStats(allCards);
      final dueBoxCards = _repetitionService.getDueBoxCards(allCards);
      
      // Get ALL box stats to show upcoming cards
      final allBoxStats = _repetitionService.getQuickBoxStats(allCards);
      final allBoxCards = _repetitionService.getQuickBoxCards(allCards);

      // Get stats for original topic decks
      final stats = <String, Map<String, int>>{};
      for (final deck in widget.decks) {
        stats[deck.topicKey] = _repetitionService.getStudyStats(deck.cards);
      }

      if (mounted) {
        setState(() {
          _globalBoxStats = dueBoxStats;
          _globalBoxCards = dueBoxCards;
          _allBoxStats = allBoxStats;
          _allBoxCards = allBoxCards;
          _deckStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Background progress loading failed: $e');
    }
  }

  void _openLevelDeck(int level, List<Flashcard> cards) async {
    if (cards.isEmpty) return;

    await FirebaseUserPreferences.savePreferences(
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
      deckKey: 'level_$level',
    );

    if (!mounted) return;

    final shouldShowTutorial = await TutorialService.shouldShowTutorial();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          topicKey: 'level_$level',
          flashcards: cards,
          showTutorial: shouldShowTutorial,
        ),
      ),
    ).then((_) {
      // Reload data when returning from flashcard screen
      _loadProgressInBackground();
    });
  }

  void _openFlashcards(BuildContext context, FlashcardDeck deck) async {
    await FirebaseUserPreferences.savePreferences(
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
      deckKey: deck.topicKey,
    );

    if (!context.mounted) return;

    final shouldShowTutorial = await TutorialService.shouldShowTutorial();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          topicKey: deck.topicKey,
          flashcards: deck.cards,
          showTutorial: shouldShowTutorial,
        ),
      ),
    ).then((_) {
      // Reload data when returning
      _loadProgressInBackground();
    });
  }

  void _onMenuSelected(String value) async {
    switch (value) {
      case 'review':
        final remembered = context.read<ReviewState>().remembered;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              cards: remembered,
              baseLanguage: widget.baseLanguage,
              targetLanguage: widget.targetLanguage,
            ),
          ),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.teal;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.fiber_new;
      case 2:
        return Icons.school;
      case 3:
        return Icons.loop;
      case 4:
        return Icons.trending_up;
      case 5:
        return Icons.emoji_events;
      default:
        return Icons.collections_bookmark;
    }
  }

  Widget _buildLevelDeckCard(int level, int cardCount, List<Flashcard> cards, {Key? key}) {
    final loc = context.read<UiLanguageProvider>().loc;
    final isDue = cardCount > 0;
    final totalCards = _allBoxStats[level] ?? 0;
    final levelName = loc.levelName(level);
    final levelColor = _getLevelColor(level);
    final levelIcon = _getLevelIcon(level);

    // Find the earliest next review date for cards in this level
    DateTime? earliestReview;
    if (!isDue && totalCards > 0) {
      final allCards = _allBoxCards[level] ?? [];
      for (final card in allCards) {
        final nextReview = _repetitionService.getNextReviewDate(card);
        if (nextReview != null) {
          if (earliestReview == null || nextReview.isBefore(earliestReview)) {
            earliestReview = nextReview;
          }
        }
      }
    }

    // Calculate time until available
    String availableText = '';
    if (!isDue && earliestReview != null) {
      final now = DateTime.now();
      final difference = earliestReview.difference(now);
      
      if (difference.inDays > 0) {
        availableText = loc.dueInDays(difference.inDays);
      } else if (difference.inHours > 0) {
        availableText = loc.dueInHours(difference.inHours);
      } else if (difference.inMinutes > 0) {
        availableText = loc.dueInMinutes(difference.inMinutes);
      } else {
        availableText = loc.availableSoon;
      }
    }

    return GestureDetector(
      onTap: isDue ? () {
        _openLevelDeck(level, cards);
      } : null,
      child: Opacity(
        opacity: isDue ? 1.0 : 0.6,
        child: Card(
          key: key,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: isDue ? 4 : 2,
          color: levelColor.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: levelColor.withOpacity(isDue ? 0.3 : 0.2),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          levelIcon,
                          color: levelColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          levelName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isDue && totalCards > 0)
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: levelColor.withOpacity(0.7),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (isDue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.cardsDue(cardCount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    )
                  else if (totalCards > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.cardsTotal(totalCards),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: levelColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          availableText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: levelColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.noCards,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicDeckCard(
    FlashcardDeck deck,
    ReviewState reviewState, {
    Key? key,
  }) {
    final loc = context.read<UiLanguageProvider>().loc;
    final deckName = TopicNames.getName(deck.topicKey, widget.baseLanguage);
    final totalCount = deck.cards.length;
    final stats = _deckStats[deck.topicKey] ?? {
      'new': totalCount,
      'due': 0,
      'review': 0,
    };
    final studiedCount = (stats['due'] ?? 0) + (stats['review'] ?? 0);
    final isComplete = totalCount > 0 && studiedCount >= totalCount;
    final cardsLeft = totalCount - studiedCount;

    return GestureDetector(
      onTap: () => _openFlashcards(context, deck),
      child: Card(
        key: key,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isComplete ? 2 : 4,
        color: isComplete ? Colors.green[50] : Colors.brown[50],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isComplete ? Colors.green : Colors.brown.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deckName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isComplete ? Colors.green[700] : Colors.brown,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isComplete)
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.brown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isComplete 
                        ? loc.completeCheckmark 
                        : '${cardsLeft} ${loc.cardsLeft}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green[700] : Colors.brown[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    final reviewState = context.watch<ReviewState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.selectDeck),
        backgroundColor: Colors.brown,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    const Icon(Icons.rate_review, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.review),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.profile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              const EmailVerificationBanner(),
              Expanded(
                child: _buildBody(reviewState),
              ),
            ],
          ),
          
          // Confetti for level completion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReviewState reviewState) {
    final loc = context.read<UiLanguageProvider>().loc;
    
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                loc.couldNotLoadProgress,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.decksStillAvailable,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!.length > 50
                      ? '${_errorMessage!.substring(0, 50)}...'
                      : _errorMessage!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeProgressData,
                icon: const Icon(Icons.refresh),
                label: Text(loc.retryLoadingProgress),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = false;
                  });
                },
                child: Text(loc.continueWithoutProgress),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      // Don't show loading screen - show empty decks immediately
      return _buildBody(reviewState);
    }

    // Build list of all decks (level decks + topic decks)
    final List<Widget> allDecks = [];

    // Add level decks that have cards due
    for (int level = 5; level >= 1; level--) {
      final dueCount = _globalBoxStats[level] ?? 0;
      final dueCards = _globalBoxCards[level] ?? [];
      
      // Only add level deck if it has cards due
      if (dueCount > 0) {
        allDecks.add(_buildLevelDeckCard(
          level,
          dueCount,
          dueCards,
          key: level == 5 && allDecks.isEmpty ? _firstLevelDeckKey : null,
        ));
      }
    }

    // Add topic decks
    final activeTopicDecks = <Widget>[];
    final completedTopicDecks = <Widget>[];

    for (int i = 0; i < widget.decks.length; i++) {
      final deck = widget.decks[i];
      final stats = _deckStats[deck.topicKey] ?? {'new': deck.cards.length, 'due': 0, 'review': 0};
      final studiedCount = (stats['due'] ?? 0) + (stats['review'] ?? 0);
      final isComplete = deck.cards.isNotEmpty && studiedCount >= deck.cards.length;

      final deckWidget = _buildTopicDeckCard(
        deck,
        reviewState,
        key: i == 0 ? _firstTopicDeckKey : null,
      );

      if (isComplete) {
        completedTopicDecks.add(deckWidget);
      } else {
        activeTopicDecks.add(deckWidget);
      }
    }

    allDecks.addAll(activeTopicDecks);
    allDecks.addAll(completedTopicDecks);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: allDecks.length,
        itemBuilder: (context, index) => allDecks[index],
      ),
    );
  }
}