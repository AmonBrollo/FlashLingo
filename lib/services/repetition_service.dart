import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';
import 'firebase_progress_service.dart';

/// Service responsible for handling spaced repetition logic (currently Leitner).
/// Keeps track of flashcard progress and determines which cards are due.
class RepetitionService {
  // Cache for progress data to avoid frequent Firebase calls
  final Map<String, FlashcardProgress> _progressCache = {};
  bool _cacheLoaded = false;

  /// Initialize the service and load cached progress
  Future<void> initialize() async {
    if (!_cacheLoaded) {
      try {
        _progressCache.clear();
        final allProgress = await FirebaseProgressService.loadAllProgress();
        _progressCache.addAll(allProgress);
        _cacheLoaded = true;
      } catch (e) {
        print('Error initializing RepetitionService: $e');
        _cacheLoaded = true; // Continue with empty cache
      }
    }
  }

  /// Generate a unique key for a flashcard (consistent with your existing logic)
  String _generateCardKey(Flashcard card) {
    // Use card ID if available, otherwise fallback to first translation.
    final key = card.translations['id'] ?? card.translations.values.first;
    return key;
  }

  /// Returns the [FlashcardProgress] for a given flashcard.
  /// Creates one if it doesn't already exist.
  FlashcardProgress getProgress(Flashcard card) {
    final key = _generateCardKey(card);

    // Return cached progress if available
    if (_progressCache.containsKey(key)) {
      return _progressCache[key]!;
    }

    // Create new progress and cache it
    final progress = FlashcardProgress();
    _progressCache[key] = progress;
    return progress;
  }

  /// Load progress for a flashcard from storage
  Future<FlashcardProgress> loadProgress(Flashcard card) async {
    final key = _generateCardKey(card);

    try {
      final progress = await FirebaseProgressService.loadProgress(card);
      _progressCache[key] = progress;
      return progress;
    } catch (e) {
      print('Error loading progress for card: $e');
      // Return cached or new progress
      return getProgress(card);
    }
  }

  /// Save progress for a flashcard
  Future<void> _saveProgress(Flashcard card, FlashcardProgress progress) async {
    final key = _generateCardKey(card);
    _progressCache[key] = progress;

    try {
      await FirebaseProgressService.saveProgress(card, progress);
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  /// Marks the flashcard as remembered (promotes its Leitner box).
  void markRemembered(Flashcard card) {
    final progress = getProgress(card);
    progress.promote();
    // Save asynchronously without blocking UI
    _saveProgress(card, progress);
  }

  /// Marks the flashcard as forgotten (resets to Box 1).
  void markForgotten(Flashcard card) {
    final progress = getProgress(card);
    progress.reset();
    // Save asynchronously without blocking UI
    _saveProgress(card, progress);
  }

  /// Returns the flashcards that are due for review today.
  List<Flashcard> dueCards(List<Flashcard> allCards) {
    return allCards.where((card) => getProgress(card).isDue()).toList();
  }

  /// Returns flashcards that have **never been studied** (new cards).
  List<Flashcard> newCards(List<Flashcard> allCards) {
    return allCards.where((card) => !getProgress(card).hasStarted).toList();
  }

  /// Returns a map of box levels → list of flashcards (useful for progress screens).
  Map<int, List<Flashcard>> groupByBox(List<Flashcard> allCards) {
    final Map<int, List<Flashcard>> grouped = {};
    for (final card in allCards) {
      final box = getProgress(card).box;
      grouped.putIfAbsent(box, () => []).add(card);
    }
    return grouped;
  }

  /// Get cards that are in review (started but not due)
  List<Flashcard> reviewCards(List<Flashcard> cards) {
    return cards.where((card) {
      final progress = getProgress(card);
      return progress.hasStarted && !progress.isDue();
    }).toList();
  }

  /// Get study statistics
  Map<String, int> getStudyStats(List<Flashcard> cards) {
    int newCount = 0;
    int dueCount = 0;
    int reviewCount = 0;

    for (final card in cards) {
      final progress = getProgress(card);
      if (!progress.hasStarted) {
        newCount++;
      } else if (progress.isDue()) {
        dueCount++;
      } else {
        reviewCount++;
      }
    }

    return {'new': newCount, 'due': dueCount, 'review': reviewCount};
  }

  /// Clear all cached progress
  void clearCache() {
    _progressCache.clear();
    _cacheLoaded = false;
  }

  /// Preload progress for multiple cards
  Future<void> preloadProgress(List<Flashcard> cards) async {
    if (!_cacheLoaded) {
      await initialize();
    }

    // Load any missing progress
    final futures = <Future>[];
    for (final card in cards) {
      final key = _generateCardKey(card);
      if (!_progressCache.containsKey(key)) {
        futures.add(loadProgress(card));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Get the next review date for a card
  DateTime? getNextReviewDate(Flashcard card) {
    final progress = getProgress(card);
    return progress.nextReview;
  }

  /// Get the current box number for a card
  int getCurrentBox(Flashcard card) {
    final progress = getProgress(card);
    return progress.box;
  }

  /// Check if a card has been started
  bool isCardStarted(Flashcard card) {
    final progress = getProgress(card);
    return progress.hasStarted;
  }

  /// Reset progress for a specific card
  Future<void> resetCardProgress(Flashcard card) async {
    final progress = FlashcardProgress();
    await _saveProgress(card, progress);
  }

  /// Delete progress for a specific card
  Future<void> deleteCardProgress(Flashcard card) async {
    final key = _generateCardKey(card);
    _progressCache.remove(key);

    try {
      await FirebaseProgressService.deleteProgress(card);
    } catch (e) {
      print('Error deleting progress: $e');
    }
  }
}
