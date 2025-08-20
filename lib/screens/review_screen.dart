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
      grouped.putIfAbsent(card.boxLevel, () => []).add(card);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByLevel(cards);
    debugPrint("Grouped: ${grouped.map((k, v) => MapEntry(k, v.length))}");

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

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2,
                  ),
                  itemCount: levelCards.length,
                  itemBuilder: (context, i) {
                    final card = levelCards[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.getTranslation(baseLanguage),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(card.getTranslation(targetLanguage)),
                          ],
                        ),
                      ),
                    );
                  },
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
