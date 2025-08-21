import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flashcard_screen.dart';
import 'review_screen.dart';
import '../models/flashcard_deck.dart';
import '../utils/ui_strings.dart';
import '../services/review_state.dart';

class DeckSelectorScreen extends StatelessWidget {
  final List<FlashcardDeck> decks;
  final String baseLanguage;
  final String targetLanguage;

  const DeckSelectorScreen({
    super.key,
    required this.decks,
    required this.baseLanguage,
    required this.targetLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.selectDeck(baseLanguage)),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Review results',
            onPressed: () {
              final remembered = context.read<ReviewState>().remembered;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    cards: remembered,
                    baseLanguage: baseLanguage,
                    targetLanguage: targetLanguage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final deckTopic = baseLanguage == "portuguese"
                ? deck.topicPortuguese
                : deck.topicEnglish;

            return Consumer<ReviewState>(
              builder: (context, reviewState, child) {
                final revealedCount = reviewState.getRevealedCount(deckTopic);
                final totalCount = deck.cards.length;
                final isComplete =
                    totalCount > 0 && revealedCount >= totalCount;

                return GestureDetector(
                  onTap: isComplete
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FlashcardScreen(
                                baseLanguage: baseLanguage,
                                targetLanguage: targetLanguage,
                                flashcards: deck.cards,
                                deckTopic: deckTopic,
                              ),
                            ),
                          );
                        },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isComplete ? 2 : 4,
                    color: isComplete ? Colors.green[100] : Colors.brown[50],
                    child: Stack(
                      children: [
                        if (isComplete)
                          const Positioned(
                            bottom: 8,
                            left: 8,
                            child: Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text(
                              deckTopic,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Text(
                            '$revealedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.brown[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
