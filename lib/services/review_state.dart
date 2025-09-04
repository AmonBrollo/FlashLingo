import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';

class ReviewState extends ChangeNotifier {
  final List<Flashcard> _remembered = [];
  final List<Flashcard> _forgotten = [];

  final Map<String, Set<Flashcard>> _deckRevealedCards = {};

  String? _currentDeckTopic;

  List<Flashcard> get remembered => List.unmodifiable(_remembered);
  List<Flashcard> get forgotten => List.unmodifiable(_forgotten);

  void setCurrentDeck(String deckTopic) {
    _currentDeckTopic = deckTopic;
  }

  void addCard(Flashcard card) {
    if (!_remembered.contains(card)) {
      _remembered.add(card);
      _forgotten.remove(card);
      if (_currentDeckTopic != null) {
        markCardRevealed(_currentDeckTopic!, card);
      }
      notifyListeners();
    }
  }

  void addForgottenCard(Flashcard card) {
    if (!_forgotten.contains(card)) {
      _forgotten.add(card);
      _remembered.remove(card);
      if (_currentDeckTopic != null) {
        markCardRevealed(_currentDeckTopic!, card);
      }
      notifyListeners();
    }
  }

  void removeForgottenCard(Flashcard card) {
    if (_forgotten.remove(card)) {
      notifyListeners();
    }
  }

  void markCardRevealed(String deckTopic, Flashcard card) {
    _deckRevealedCards.putIfAbsent(deckTopic, () => <Flashcard>{});
    final wasAlreadyRevealed = _deckRevealedCards[deckTopic]!.contains(card);
    _deckRevealedCards[deckTopic]!.add(card);

    if (!wasAlreadyRevealed) {
      notifyListeners();
    }
  }

  int getRevealedCount(String deckTopic) {
    return _deckRevealedCards[deckTopic]?.length ?? 0;
  }

  bool isCardRevealed(String deckTopic, Flashcard card) {
    return _deckRevealedCards[deckTopic]?.contains(card) ?? false;
  }

  void clearDeck(String deckTopic) {
    _deckRevealedCards.remove(deckTopic);
    notifyListeners();
  }

  void clear() {
    _remembered.clear();
    _forgotten.clear();
    _deckRevealedCards.clear();
    _currentDeckTopic = null;
    notifyListeners();
  }
}
