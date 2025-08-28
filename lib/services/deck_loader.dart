import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../utils/topic_names.dart';

class DeckLoader {
  // Load all decks dynamically
  static Future<List<FlashcardDeck>> loadDecks() async {
    List<FlashcardDeck> decks = [];

    for (final topic in TopicNames.allTopics) {
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/data/$topic.json',
        );
        final List<dynamic> jsonData = json.decode(jsonString);

        final translation = TopicNames.names[topic];
        if (translation == null) {
          debugPrint('Warning: No translation found for topic $topic');
          continue;
        }

        decks.add(
          FlashcardDeck(
            topicKey: topic, // unique identifier
            topicEnglish: translation["english"]!,
            topicPortuguese: translation["portuguese"]!,
            cards: jsonData.map((item) => Flashcard.fromJson(item)).toList(),
          ),
        );
      } catch (e) {
        // If the JSON for a topic is missing or invalid, skip it
        debugPrint('Warning: Could not load topic $topic: $e');
      }
    }

    return decks;
  }
}
