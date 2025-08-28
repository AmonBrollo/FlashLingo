import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'login_screen.dart';
import 'base_language_selector_screen.dart';
import 'target_language_selector_screen.dart';
import 'flashcard_screen.dart';
import '../services/deck_loader.dart';
import '../models/flashcard_deck.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  Future<Widget> _determineStartScreen() async {
    // Check login
    final loggedIn = UserPreferences.isLoggedIn(); // removed await
    if (!loggedIn) return const LoginScreen();

    // Load preferences
    final prefs = await UserPreferences.loadPreferences();
    final baseLang = prefs['baseLanguage'];
    final targetLang = prefs['targetLanguage'];
    final lastDeckKey = prefs['lastDeckKey'];

    // Validate preferences
    if (baseLang == null) return const BaseLanguageSelectorScreen();
    if (targetLang == null) {
      return TargetLanguageSelectorScreen(baseLanguage: baseLang);
    }

    // Load decks
    final decks = await DeckLoader.loadDecks();
    if (decks.isEmpty) {
      // No decks available, maybe show an empty state
      return const Scaffold(body: Center(child: Text('No decks found')));
    }

    // Validate deck
    FlashcardDeck initialDeck;
    if (lastDeckKey != null) {
      initialDeck = decks.firstWhere(
        (d) => d.topicKey == lastDeckKey,
        orElse: () => decks.first, // safe fallback
      );
    } else {
      initialDeck = decks.first;
    }

    // Go directly to flashcards
    return FlashcardScreen(
      flashcards: initialDeck.cards,
      baseLanguage: baseLang,
      targetLanguage: targetLang,
      topicKey: initialDeck.topicKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
