import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';
import 'firebase_progress_service.dart';
import 'sync_service.dart';

/// Service responsible for handling spaced repetition logic (Leitner system).
/// Keeps track of flashcard progress and determines which cards are due.
/// Now uses singleton pattern for performance optimization.
/// NOW WITH LANGUAGE-SPECIFIC PROGRESS!
class RepetitionService {
  // Singleton instance
  static final RepetitionService _instance = RepetitionService._internal();
  factory RepetitionService() => _instance;
  RepetitionService._internal();

  // Cache for progress data to avoid frequent Firebase calls
  final Map<String, FlashcardProgress> _progressCache = {};
  bool _cacheLoaded = false;
  bool _isInitializing = false;

  // Current language context
  String? _currentBaseLanguage;
  String? _currentTargetLanguage;

  /// Initialize the service and load cached progress
  Future<void> initialize({String? baseLanguage, String? targetLanguage}) async {
    if (_cacheLoaded || _isInitializing) {
      return; // Already initialized or in progress
    }

    _isInitializing = true;
    
    // Store language context
    _currentBaseLanguage = baseLanguage;
    _currentTargetLanguage = targetLanguage;

    try {
      _progressCache.clear();

      // Load with a SHORT timeout
      final allProgress = await FirebaseProgressService.loadAllProgress()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('Progress loading timed out - using empty cache');
              return <String, FlashcardProgress>{};
            },
          );

      _progressCache.addAll(allProgress);
      _cacheLoaded = true;
      print(
        'RepetitionService initialized with ${_progressCache.length} cards (FAST)',
      );
    } catch (e) {
      print('Error initializing RepetitionService: $e');
      _cacheLoaded = true; // Continue with empty cache
    } finally {
      _isInitializing = false;
    }
  }

  /// Set language context for the service
  void setLanguageContext(String baseLanguage, String targetLanguage) {
    _currentBaseLanguage = baseLanguage;
    _currentTargetLanguage = targetLanguage;
  }

  /// Get box statistics with DUE cards only (for level decks)
  Map<int, int> getDueBoxStats(
    List<Flashcard> cards, {
    String? baseLanguage,
    String? targetLanguage,
  }) {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for getDueBoxStats');
      return {-1: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    
    final stats = <int, int>{-1: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final card in cards) {
      final key = _generateCardKey(card, base, target);
      final progress = _progressCache[key];
      
      if (progress != null && progress.hasStarted && progress.isDue()) {
        final box = progress.box;
        if ((box >= 1 && box <= 5) || box == -1) {
          stats[box] = (stats[box] ?? 0) + 1;
        }
      }
    }
    
    return stats;
  }

  /// Get DUE cards grouped by box (for level decks)
  Map<int, List<Flashcard>> getDueBoxCards(
    List<Flashcard> cards, {
    String? baseLanguage,
    String? targetLanguage,
  }) {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for getDueBoxCards');
      return {-1: [], 1: [], 2: [], 3: [], 4: [], 5: []};
    }
    
    final boxCards = <int, List<Flashcard>>{
      -1: [],
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
    };
    
    for (final card in cards) {
      final key = _generateCardKey(card, base, target);
      final progress = _progressCache[key];
      
      // Only include cards that are due for review
      if (progress != null && progress.hasStarted && progress.isDue()) {
        final box = progress.box;
        if ((box >= 1 && box <= 5) || box == -1) {
          boxCards[box]!.add(card);
        }
      }
    }
    
    return boxCards;
  }

  /// Get box statistics without loading full progress (fast) - ALL cards including not due
  Map<int, int> getQuickBoxStats(
    List<Flashcard> cards, {
    String? baseLanguage,
    String? targetLanguage,
  }) {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for getQuickBoxStats');
      return {-1: 0, 0: cards.length, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
    
    final stats = <int, int>{-1: 0, 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final card in cards) {
      final key = _generateCardKey(card, base, target);
      final progress = _progressCache[key];
      
      if (progress != null) {
        final box = progress.box;
        stats[box] = (stats[box] ?? 0) + 1;
      } else {
        // Default to box 0 for uncached cards (unseen)
        stats[0] = (stats[0] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  /// Get cards grouped by box (optimized for cached data) - ALL cards including not due
  Map<int, List<Flashcard>> getQuickBoxCards(
    List<Flashcard> cards, {
    String? baseLanguage,
    String? targetLanguage,
  }) {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for getQuickBoxCards');
      return {-1: [], 0: cards, 1: [], 2: [], 3: [], 4: [], 5: []};
    }
    
    final boxCards = <int, List<Flashcard>>{
      -1: [],
      0: [],
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
    };
    
    for (final card in cards) {
      final key = _generateCardKey(card, base, target);
      final progress = _progressCache[key];
      
      final box = progress?.box ?? 0;
      boxCards[box]!.add(card);
    }
    
    return boxCards;
  }

  /// Check if cache is loaded
  bool get isCacheLoaded => _cacheLoaded;

  /// Force reload cache
  Future<void> reloadCache() async {
    _cacheLoaded = false;
    await initialize(
      baseLanguage: _currentBaseLanguage,
      targetLanguage: _currentTargetLanguage,
    );
  }

  /// Generate a unique key for a flashcard WITH language context
  String _generateCardKey(Flashcard card, String baseLanguage, String targetLanguage) {
    final cardId = card.translations['id'] ?? card.translations.values.first;
    return '${baseLanguage}_${targetLanguage}_$cardId';
  }

  /// Returns the [FlashcardProgress] for a given flashcard.
  /// Creates one if it doesn't already exist.
  FlashcardProgress getProgress(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for getProgress');
      return FlashcardProgress();
    }
    
    final key = _generateCardKey(card, base, target);

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
  Future<FlashcardProgress> loadProgress(
    Flashcard card, {
    String? baseLanguage,
    String? targetLanguage,
  }) async {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for loadProgress');
      return FlashcardProgress();
    }
    
    final key = _generateCardKey(card, base, target);

    try {
      final progress = await FirebaseProgressService.loadProgress(card, base, target);
      _progressCache[key] = progress;
      return progress;
    } catch (e) {
      print('Error loading progress for card: $e');
      return getProgress(card, baseLanguage: base, targetLanguage: target);
    }
  }

  /// Save progress for a flashcard
  Future<void> _saveProgress(
    Flashcard card,
    FlashcardProgress progress, {
    String? baseLanguage,
    String? targetLanguage,
  }) async {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for _saveProgress');
      return;
    }
    
    final key = _generateCardKey(card, base, target);
    _progressCache[key] = progress;

    try {
      await FirebaseProgressService.saveProgress(card, progress, base, target);
      SyncService().markDataChanged();
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  /// Marks the flashcard as remembered (promotes its Leitner box).
  void markRemembered(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    progress.promote();
    _saveProgress(card, progress, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
  }

  /// Marks the flashcard as forgotten (resets to Box 1).
  void markForgotten(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    progress.reset();
    _saveProgress(card, progress, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
  }

  /// Returns the flashcards that are due for review today.
  List<Flashcard> dueCards(List<Flashcard> allCards, {String? baseLanguage, String? targetLanguage}) {
    return allCards.where((card) => 
      getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage).isDue()
    ).toList();
  }

  /// Returns flashcards that have **never been studied** (new cards - box 0).
  List<Flashcard> newCards(List<Flashcard> allCards, {String? baseLanguage, String? targetLanguage}) {
    return allCards.where((card) => 
      !getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage).hasStarted
    ).toList();
  }

  /// Returns a map of box levels → list of flashcards.
  Map<int, List<Flashcard>> groupByBox(List<Flashcard> allCards, {String? baseLanguage, String? targetLanguage}) {
    final Map<int, List<Flashcard>> grouped = {};
    for (final card in allCards) {
      final box = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage).box;
      grouped.putIfAbsent(box, () => []).add(card);
    }
    return grouped;
  }

  /// Get cards that are in review (started but not due)
  List<Flashcard> reviewCards(List<Flashcard> cards, {String? baseLanguage, String? targetLanguage}) {
    return cards.where((card) {
      final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
      return progress.hasStarted && !progress.isDue();
    }).toList();
  }

  /// Get study statistics
  Map<String, int> getStudyStats(List<Flashcard> cards, {String? baseLanguage, String? targetLanguage}) {
    int newCount = 0;
    int dueCount = 0;
    int reviewCount = 0;

    for (final card in cards) {
      final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
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
  Future<void> preloadProgress(
    List<Flashcard> cards, {
    String? baseLanguage,
    String? targetLanguage,
  }) async {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for preloadProgress');
      return;
    }
    
    if (!_cacheLoaded) {
      await initialize(baseLanguage: base, targetLanguage: target);
    }

    for (final card in cards) {
      final key = _generateCardKey(card, base, target);
      if (!_progressCache.containsKey(key)) {
        _progressCache[key] = FlashcardProgress();
      }
    }

    print(
      'Preloaded progress for ${cards.length} cards (${_progressCache.length} total in cache)',
    );
  }

  /// Get the next review date for a card
  DateTime? getNextReviewDate(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    return progress.nextReview;
  }

  /// Get the current box number for a card
  int getCurrentBox(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    return progress.box;
  }

  /// Check if a card has been started
  bool isCardStarted(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    return progress.hasStarted;
  }

  /// Check if a card is due for review
  bool isCardDue(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    return progress.isDue();
  }

  /// Get days until card is due (negative if overdue)
  int daysUntilDue(Flashcard card, {String? baseLanguage, String? targetLanguage}) {
    final progress = getProgress(card, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
    return progress.daysUntilReview();
  }

  /// Reset progress for a specific card
  Future<void> resetCardProgress(Flashcard card, {String? baseLanguage, String? targetLanguage}) async {
    final progress = FlashcardProgress();
    await _saveProgress(card, progress, baseLanguage: baseLanguage, targetLanguage: targetLanguage);
  }

  /// Delete progress for a specific card
  Future<void> deleteCardProgress(Flashcard card, {String? baseLanguage, String? targetLanguage}) async {
    final base = baseLanguage ?? _currentBaseLanguage;
    final target = targetLanguage ?? _currentTargetLanguage;
    
    if (base == null || target == null) {
      print('Warning: Language context not set for deleteCardProgress');
      return;
    }
    
    final key = _generateCardKey(card, base, target);
    _progressCache.remove(key);

    try {
      await FirebaseProgressService.deleteProgress(card, base, target);
      SyncService().markDataChanged();
    } catch (e) {
      print('Error deleting progress: $e');
    }
  }
}