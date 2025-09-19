import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'flashcard_screen.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';
import '../services/review_state.dart';
import '../services/firebase_user_preferences.dart';
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

  void _openFlashcards(BuildContext context, FlashcardDeck deck) async {
    // Save user preferences when they select a deck
    await FirebaseUserPreferences.savePreferences(
      baseLanguage: baseLanguage,
      targetLanguage: targetLanguage,
      deckKey: deck.topicKey,
    );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: baseLanguage,
          targetLanguage: targetLanguage,
          topicKey: deck.topicKey,
          flashcards: deck.cards,
        ),
      ),
    );
  }

  void _openForgottenCards(
    BuildContext context,
    List<Flashcard> forgottenCards,
  ) {
    if (forgottenCards.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          baseLanguage: baseLanguage,
          targetLanguage: targetLanguage,
          topicKey: 'forgotten',
          flashcards: forgottenCards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = context.watch<ReviewState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.selectDeck(baseLanguage)),
        backgroundColor: Colors.brown,
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
          itemCount: decks.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final List<Flashcard> forgottenCards = reviewState.forgotten;

              return GestureDetector(
                onTap: forgottenCards.isEmpty
                    ? null
                    : () => _openForgottenCards(context, forgottenCards),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: forgottenCards.isEmpty ? 1 : 4,
                  color: Colors.red[50],
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: Text(
                            'Forgotten Cards',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
                          '${forgottenCards.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final deck = decks[index - 1];
            final deckName = TopicNames.getName(deck.topicKey, baseLanguage);
            final revealedCount = reviewState.getRevealedCount(deck.topicKey);
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
