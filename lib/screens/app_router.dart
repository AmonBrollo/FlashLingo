import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/deck_loader.dart';
import '../models/flashcard_deck.dart';
import 'login_screen.dart';
import 'base_language_selector_screen.dart';
import 'target_language_selector_screen.dart';
import 'flashcard_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  Future<Widget> _determineStartScreen() async {
    try {
      // Check login (using Firebase instead of old UserPreferences)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const LoginScreen();

      // Load preferences from Firebase (with local fallback)
      final prefs = await FirebaseUserPreferences.loadPreferences();
      final baseLang = prefs['baseLanguage'];
      final targetLang = prefs['targetLanguage'];
      final deckKey =
          prefs['deckKey']; // Changed from lastDeckKey to match your new structure

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
      if (deckKey != null) {
        initialDeck = decks.firstWhere(
          (d) => d.topicKey == deckKey,
          orElse: () => decks.first, // safe fallback
        );
      } else {
        initialDeck = decks.first;
      }

      // Initialize the repetition service and preload progress
      final repetitionService = RepetitionService();
      await repetitionService.initialize();
      await repetitionService.preloadProgress(initialDeck.cards);

      // Go directly to flashcards
      return FlashcardScreen(
        flashcards: initialDeck.cards,
        baseLanguage: baseLang,
        targetLanguage: targetLang,
        topicKey: initialDeck.topicKey,
      );
    } catch (e) {
      print('Error determining start screen: $e');
      // Fallback to base language selector on error
      return const BaseLanguageSelectorScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.brown,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading FlashLango...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading app',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force rebuild to retry
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AppRouter()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Clear preferences and restart setup
                      FirebaseUserPreferences.clearPreferences().then((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BaseLanguageSelectorScreen(),
                          ),
                        );
                      });
                    },
                    child: const Text('Reset Setup'),
                  ),
                ],
              ),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
