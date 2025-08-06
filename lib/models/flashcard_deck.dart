import 'flashcard.dart';

class FlashcardDeck {
  final String topicEnglish;
  final String topicPortuguese;
  final List<Flashcard> cards;

  FlashcardDeck({
    required this.topicEnglish,
    required this.topicPortuguese,
    required this.cards,
  });
}
