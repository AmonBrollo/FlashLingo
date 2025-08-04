import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';

class DeckLoader {
  static Future<List<FlashcardDeck>> loadDecks() async {
    final topics = [
      "adjectives",
      "animals",
      "art",
      "beverages",
      "body",
      "clothing",
      "colors",
      "days",
      "directions",
      "electronics",
      "food",
      "home",
      "jobs",
      "locations",
      "materials",
      "math",
      "miscellaneous",
      "months",
      "nature",
      "numbers",
      "people",
      "pronouns",
      "seasons",
      "society",
      "time",
      "transportation",
      "verbs",
    ];
    List<FlashcardDeck> decks = [];

    for (final topic in topics) {
      final String jsonString = await rootBundle.loadString(
        'assets/data/$topic.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      decks.add(
        FlashcardDeck(
          topic: topic[0].toUpperCase() + topic.substring(1),
          cards: jsonData.map((item) => Flashcard.fromJson(item)).toList(),
        ),
      );
    }

    return decks;
  }
}
