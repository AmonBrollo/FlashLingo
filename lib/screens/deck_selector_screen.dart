import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flashcard_screen.dart';
import 'review_screen.dart';
import '../models/flashcard_deck.dart';
import '../services/review_state.dart';
import '../utils/topic_names.dart';
import '../utils/ui_strings.dart';

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

  void _openFlashcards(BuildContext context, FlashcardDeck deck) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: baseLanguage,
          targetLanguage: targetLanguage,
          topicKey: deck.topicKey, // keep deckKey for internal tracking
          flashcards: deck.cards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = context.read<ReviewState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.selectDeck(baseLanguage)),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Review results',
            onPressed: () {
              final remembered = reviewState.remembered;
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
            final deckName = TopicNames.getName(deck.topicKey, baseLanguage);
            final revealedCount = reviewState.getRevealedCount(deckName);
            final totalCount = deck.cards.length;
            final isComplete = totalCount > 0 && revealedCount >= totalCount;

            return GestureDetector(
              onTap: isComplete ? null : () => _openFlashcards(context, deck),
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
                          deckName,
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
        ),
      ),
    );
  }
}
