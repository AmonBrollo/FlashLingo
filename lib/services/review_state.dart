import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';

class ReviewState extends ChangeNotifier {
  final List<Flashcard> _remembered = [];

  List<Flashcard> get remembered => List.unmodifiable(_remembered);

  void addCard(Flashcard card) {
    if (!_remembered.contains(card)) {
      _remembered.add(card);
      notifyListeners();
    }
  }

  void clear() {
    _remembered.clear();
    notifyListeners();
  }
}
