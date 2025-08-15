import 'package:flutter/material.dart';
import 'deck_selector_screen.dart';
import '../services/deck_loader.dart';
import '../utils/ui_strings.dart';

class TargetLanguageSelectorScreen extends StatelessWidget {
  final String baseLanguage;
  const TargetLanguageSelectorScreen({super.key, required this.baseLanguage});

  void _selectTargetLanguage(
    BuildContext context,
    String targetLanguage,
  ) async {
    DeckLoader.loadDecks().then((decks) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage,
            decks: decks,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Text(UiStrings.selectTargetLanguage(baseLanguage)),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectTargetLanguage(context, "hungarian"),
              child: const Text("Hungarian"),
            ),
            // Add more target languages here
          ],
        ),
      ),
    );
  }
}
