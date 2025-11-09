import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'flashcard_screen.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';
import '../models/tutorial_step.dart';
import '../services/review_state.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/tutorial_service.dart';
import '../utils/topic_names.dart';
import '../utils/ui_strings.dart';
import '../widgets/email_verification_banner.dart';
import '../widgets/tutorial_overlay.dart';
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
  
  // Box level stats - global across all topics
  Map<int, int> _globalBoxStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  Map<int, List<Flashcard>> _globalBoxCards = {1: [], 2: [], 3: [], 4: [], 5: []};
  
  // Original topic deck stats
  Map<String, Map<String, int>> _deckStats = {};
  
  bool _showTutorial = false;
  late ConfettiController _confettiController;

  // Tutorial keys
  final GlobalKey _firstLevelDeckKey = GlobalKey();
  final GlobalKey _firstTopicDeckKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initializeProgressData();
    _checkTutorial();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkTutorial() async {
    if (widget.showTutorial) {
      final shouldShow = await TutorialService.shouldShowTutorial();
      if (shouldShow && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showTutorial = true);
          }
        });
      }
    }
  }

  Future<void> _initializeProgressData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    // Set default stats
    final stats = <String, Map<String, int>>{};
    int totalCards = 0;
    
    for (final deck in widget.decks) {
      stats[deck.topicKey] = {'new': deck.cards.length, 'due': 0, 'review': 0};
      totalCards += deck.cards.length;
    }

    // Default: all cards in box 1
    setState(() {
      _deckStats = stats;
      _globalBoxStats = {1: totalCards, 2: 0, 3: 0, 4: 0, 5: 0};
      _isLoading = false;
    });

    // Load progress in background
    _loadProgressInBackground();
  }

  Future<void> _loadProgressInBackground() async {
    try {
      await _repetitionService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Progress initialization timed out - continuing with defaults');
        },
      );

      // Collect all cards from all decks
      final allCards = <Flashcard>[];
      for (final deck in widget.decks) {
        allCards.addAll(deck.cards);
      }

      // Preload progress for all cards
      await _repetitionService.preloadProgress(allCards);

      // Get global box breakdown (all topics combined)
      final boxBreakdown = _repetitionService.groupByBox(allCards);
      final globalBoxStats = <int, int>{};
      final globalBoxCards = <int, List<Flashcard>>{};
      
      for (int box = 1; box <= 5; box++) {
        final cardsInBox = boxBreakdown[box] ?? [];
        globalBoxStats[box] = cardsInBox.length;
        globalBoxCards[box] = cardsInBox;
      }

      // Get stats for original topic decks
      final stats = <String, Map<String, int>>{};
      for (final deck in widget.decks) {
        stats[deck.topicKey] = _repetitionService.getStudyStats(deck.cards);
      }

      if (mounted) {
        setState(() {
          _globalBoxStats = globalBoxStats;
          _globalBoxCards = globalBoxCards;
          _deckStats = stats;
        });
      }
    } catch (e) {
      print('Background progress loading failed: $e');
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

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'New';
      case 2:
        return 'Learning';
      case 3:
        return 'Reviewing';
      case 4:
        return 'Mastering';
      case 5:
        return 'Mastered';
      default:
        return 'Level $level';
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
    final isComplete = cardCount == 0;
    final levelName = _getLevelName(level);
    final levelColor = _getLevelColor(level);
    final levelIcon = _getLevelIcon(level);

    return GestureDetector(
      onTap: isComplete ? null : () {
        _openLevelDeck(level, cards);
      },
      child: Card(
        key: key,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isComplete ? 2 : 4,
        color: isComplete ? Colors.green[50] : levelColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isComplete ? Colors.green : levelColor.withOpacity(0.3),
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
                        color: isComplete 
                            ? Colors.green.withOpacity(0.2)
                            : levelColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        levelIcon,
                        color: isComplete ? Colors.green : levelColor,
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
                          color: isComplete ? Colors.green[700] : levelColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isComplete)
                      const Icon(
                        Icons.check_circle,
                        size: 24,
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
                        : levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isComplete ? 'Complete ✓' : '$cardCount cards left',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green[700] : levelColor,
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

  Widget _buildTopicDeckCard(
    FlashcardDeck deck,
    ReviewState reviewState, {
    Key? key,
  }) {
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
                    isComplete ? 'Complete ✓' : '$cardsLeft cards left',
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

  List<TutorialStep> _getTutorialSteps() {
    final allSteps = TutorialService.getStepsForScreen(
      widget.baseLanguage,
      TutorialConfig.screenDeckSelector,
    );

    return allSteps.map((step) {
      if (step.id == TutorialConfig.deckSelectorDeckCard) {
        return TutorialStep(
          id: step.id,
          title: step.title,
          message: step.message,
          targetKey: _firstLevelDeckKey,
          messagePosition: step.messagePosition,
          icon: step.icon,
          screen: step.screen,
        );
      }
      return step;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = context.watch<ReviewState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.selectDeck(widget.baseLanguage)),
        backgroundColor: Colors.brown,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, size: 20),
                    SizedBox(width: 8),
                    Text('Review'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const EmailVerificationBanner(),
              Expanded(
                child: _buildBody(reviewState),
              ),
            ],
          ),
          if (_showTutorial)
            TutorialOverlay(
              steps: _getTutorialSteps(),
              language: widget.baseLanguage,
              onComplete: () {
                setState(() => _showTutorial = false);
              },
              onSkip: () {
                setState(() => _showTutorial = false);
              },
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
              const Text(
                'Could not load progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Don\'t worry, your decks are still available!',
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
                label: const Text('Retry Loading Progress'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = false;
                  });
                },
                child: const Text('Continue Without Progress Data'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            ),
            const SizedBox(height: 16),
            const Text('Loading progress...'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() => _isLoading = false);
              },
              child: const Text('Skip and continue'),
            ),
          ],
        ),
      );
    }

    // Build list of all decks (level decks + topic decks)
    final List<Widget> allDecks = [];

    // Add level decks (highest level first, only if they have cards)
    // Only show level decks that have cards (no completed/empty state)
    for (int level = 5; level >= 1; level--) {
      final cardCount = _globalBoxStats[level] ?? 0;
      final cards = _globalBoxCards[level] ?? [];
      
      // Only add if there are cards in this level
      if (cardCount > 0) {
        allDecks.add(_buildLevelDeckCard(
          level,
          cardCount,
          cards,
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
      final isComplete = deck.cards.length > 0 && studiedCount >= deck.cards.length;

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