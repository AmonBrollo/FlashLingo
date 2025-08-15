import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../utils/topic_names.dart';

class DeckLoader {
  static Future<List<FlashcardDeck>> loadDecks() async {
    final topics = [
      "adjectives",
      "animals",
      "art",
      "beverages",
      "body",
      "clothing",
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

      final translation = TopicNames.names[topic]!;

      decks.add(
        FlashcardDeck(
          topicEnglish: translation["english"]!,
          topicPortuguese: translation["portuguese"]!,
          cards: jsonData.map((item) => Flashcard.fromJson(item)).toList(),
        ),
      );
    }

    return decks;
  }
}
