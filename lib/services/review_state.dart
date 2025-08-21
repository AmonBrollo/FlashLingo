import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';

class ReviewState extends ChangeNotifier {
  final List<Flashcard> _remembered = [];
  final List<Flashcard> _forgotten = [];

  List<Flashcard> get remembered => List.unmodifiable(_remembered);
  List<Flashcard> get forgotten => List.unmodifiable(_forgotten);

  void addCard(Flashcard card) {
    if (!_remembered.contains(card)) {
      _remembered.add(card);
      notifyListeners();
    }
  }

  void addForgottenCard(Flashcard card) {
    if (!_forgotten.contains(card)) {
      _forgotten.add(card);
      notifyListeners();
    }
  }

  void clear() {
    _remembered.clear();
    _forgotten.clear();
    notifyListeners();
  }
}
