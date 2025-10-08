import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flashcard_screen.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';
import '../services/review_state.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/loading_with_timeout.dart';
import '../utils/topic_names.dart';
import '../utils/ui_strings.dart';
import 'profile_screen.dart';
import 'review_screen.dart';

class DeckSelectorScreen extends StatefulWidget {
  final List<FlashcardDeck> decks;
  final String baseLanguage;
  final String targetLanguage;

  const DeckSelectorScreen({
    super.key,
    required this.decks,
    required this.baseLanguage,
    required this.targetLanguage,
  });

  @override
  State<DeckSelectorScreen> createState() => _DeckSelectorScreenState();
}

class _DeckSelectorScreenState extends State<DeckSelectorScreen> {
  final RepetitionService _repetitionService = RepetitionService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, Map<String, int>> _deckStats = {};

  @override
  void initState() {
    super.initState();
    _initializeProgressData();
  }

  Future<void> _initializeProgressData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Initialize repetition service with timeout
      await LoadingWithTimeout.execute(
        operation: () => _repetitionService.initialize(),
        timeout: const Duration(seconds: 8),
        operationName: 'Initialize repetition service',
      );

      // Calculate stats for each deck with individual timeouts
      final stats = <String, Map<String, int>>{};

      for (final deck in widget.decks) {
        try {
          // Preload progress for this deck with timeout
          await LoadingWithTimeout.execute(
            operation: () => _repetitionService.preloadProgress(deck.cards),
            timeout: const Duration(seconds: 5),
            operationName: 'Preload ${deck.topicKey}',
          );

          // Calculate statistics (this is local, no timeout needed)
          stats[deck.topicKey] = _repetitionService.getStudyStats(deck.cards);
        } catch (e) {
          print('Error loading deck ${deck.topicKey}: $e');
          // Continue with next deck even if this one fails
          stats[deck.topicKey] = {
            'new': deck.cards.length,
            'due': 0,
            'review': 0,
          };
        }
      }

      if (mounted) {
        setState(() {
          _deckStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading deck progress: $e');

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;

          // Set default stats for all decks so they're still accessible
          for (final deck in widget.decks) {
            _deckStats[deck.topicKey] = {
              'new': deck.cards.length,
              'due': 0,
              'review': 0,
            };
          }
        });
      }
    }
  }

  void _openFlashcards(BuildContext context, FlashcardDeck deck) async {
    // Save user preferences when they select a deck
    await FirebaseUserPreferences.savePreferences(
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
      deckKey: deck.topicKey,
    );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          topicKey: deck.topicKey,
          flashcards: deck.cards,
        ),
      ),
    );
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

  void _openForgottenCards(
    BuildContext context,
    List<Flashcard> forgottenCards,
  ) {
    if (forgottenCards.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          topicKey: 'forgotten',
          flashcards: forgottenCards,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Map<String, int> stats, int totalCount) {
    final newCount = stats['new'] ?? totalCount;
    final dueCount = stats['due'] ?? 0;
    final reviewCount = stats['review'] ?? 0;
    final studiedCount = dueCount + reviewCount;

    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: studiedCount / totalCount,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                studiedCount == totalCount ? Colors.green : Colors.brown,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (newCount > 0) _buildStatChip('New', newCount, Colors.blue),
              if (dueCount > 0) _buildStatChip('Due', dueCount, Colors.orange),
              if (reviewCount > 0)
                _buildStatChip('Learning', reviewCount, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.8),
        ),
      ),
    );
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
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, size: 20),
                    SizedBox(width: 8),
                    Text('Review'),
                  ],
                ),
              ),
              PopupMenuItem(
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
      body: _buildBody(reviewState),
    );
  }

  Widget _buildBody(ReviewState reviewState) {
    // Show error state with retry option
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

    // Show loading state with timeout indicator
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
                setState(() {
                  _isLoading = false;
                  // Set default stats if loading is taking too long
                  for (final deck in widget.decks) {
                    _deckStats[deck.topicKey] = {
                      'new': deck.cards.length,
                      'due': 0,
                      'review': 0,
                    };
                  }
                });
              },
              child: const Text('Skip and continue'),
            ),
          ],
        ),
      );
    }

    // Show normal deck grid
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.decks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildForgottenCardsCard(reviewState);
          }

          final deck = widget.decks[index - 1];
          return _buildDeckCard(deck, reviewState);
        },
      ),
    );
  }

  Widget _buildForgottenCardsCard(ReviewState reviewState) {
    final List<Flashcard> forgottenCards = reviewState.forgotten;

    return GestureDetector(
      onTap: forgottenCards.isEmpty
          ? null
          : () => _openForgottenCards(context, forgottenCards),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: forgottenCards.isEmpty ? 1 : 4,
        color: Colors.red[50],
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Forgotten Cards',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (forgottenCards.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Review ${forgottenCards.length} cards',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Text(
                '${forgottenCards.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(FlashcardDeck deck, ReviewState reviewState) {
    final deckName = TopicNames.getName(deck.topicKey, widget.baseLanguage);
    final revealedCount = reviewState.getRevealedCount(deck.topicKey);
    final totalCount = deck.cards.length;
    final stats =
        _deckStats[deck.topicKey] ?? {'new': totalCount, 'due': 0, 'review': 0};
    final studiedCount = (stats['due'] ?? 0) + (stats['review'] ?? 0);
    final isComplete = totalCount > 0 && studiedCount >= totalCount;

    return GestureDetector(
      onTap: () => _openFlashcards(context, deck),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: isComplete ? Colors.green[50] : Colors.brown[50],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with completion status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deckName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
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
              // Progress information
              _buildProgressIndicator(stats, totalCount),
              const SizedBox(height: 8),
              // Total card count
              Text(
                '$revealedCount/$totalCount cards',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
