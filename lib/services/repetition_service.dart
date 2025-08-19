import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';

/// Service responsible for handling spaced repetition logic (currently Leitner).
/// Keeps track of flashcard progress and determines which cards are due.
class RepetitionService {
  final Map<String, FlashcardProgress> _progressMap = {};

  /// Returns the [FlashcardProgress] for a given flashcard.
  /// Creates one if it doesn't already exist.
  FlashcardProgress getProgress(Flashcard card) {
    // Use card ID if available, otherwise fallback to first translation.
    final key = card.translations['id'] ?? card.translations.values.first;
    return _progressMap.putIfAbsent(key, () => FlashcardProgress());
  }

  /// Marks the flashcard as remembered (promotes its Leitner box).
  void markRemembered(Flashcard card) {
    final progress = getProgress(card);
    progress.promote();
  }

  /// Marks the flashcard as forgotten (resets to Box 1).
  void markForgotten(Flashcard card) {
    final progress = getProgress(card);
    progress.reset();
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
}
