import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';

class SpacedRepetitionService {
  final Map<String, FlashcardProgress> _progressMap = {};

  FlashcardProgress getProgress(Flashcard card) {
    return _progressMap.putIfAbsent(
      card.translations['id'] ?? card.translations.values.first,
      () => FlashcardProgress(),
    );
  }

  void markRemembered(Flashcard card) {
    getProgress(card).promote();
  }

  void markForgotten(Flashcard card) {
    getProgress(card).reset();
  }

  List<Flashcard> dueCards(List<Flashcard> allCards) {
    return allCards.where((card) => getProgress(card).isDue()).toList();
  }
}
