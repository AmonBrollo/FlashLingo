import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../utils/ui_strings.dart';

class ReviewScreen extends StatelessWidget {
  final List<Flashcard> cards;
  final String baseLanguage;
  final String targetLanguage;

  const ReviewScreen({
    super.key,
    required this.cards,
    required this.baseLanguage,
    required this.targetLanguage,
  });

  Map<int, List<Flashcard>> _groupByLevel(List<Flashcard> all) {
    final Map<int, List<Flashcard>> grouped = {};
    for (final card in all) {
      grouped.putIfAbsent(card.level, () => []).add(card);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByLevel(cards);

    final levels = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.reviewTitle(baseLanguage)),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final levelCards = grouped[level]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Level $level",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 8),
                ...levelCards.map(
                  (card) => Card(
                    child: ListTile(
                      title: Text(card.getTranslation(baseLanguage)),
                      subtitle: Text(card.getTranslation(targetLanguage)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
