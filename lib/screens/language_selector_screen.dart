import 'package:flutter/material.dart';
import '../services/deck_loader.dart';
import 'deck_selector_screen.dart';

class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  void _navigateToDecks(BuildContext context, String baseLanguage) {
    DeckLoader.loadDecks().then((decks) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeckSelectorScreen(decks: decks, baseLanguage: baseLanguage),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Choose Base Language"),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.flag),
              label: const Text(
                "Português → Húngaro",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => _navigateToDecks(context, "portuguese"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.flag),
              label: const Text(
                "English → Hungarian",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => _navigateToDecks(context, "english"),
            ),
          ],
        ),
      ),
    );
  }
}
