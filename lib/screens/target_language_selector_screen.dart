import 'package:flutter/material.dart';
import 'deck_selector_screen.dart';
import '../services/deck_loader.dart';
import '../widgets/language_option_button.dart';
import '../utils/ui_strings.dart';

class TargetLanguageSelectorScreen extends StatelessWidget {
  final String baseLanguage;
  const TargetLanguageSelectorScreen({super.key, required this.baseLanguage});

  void _selectTargetLanguage(
    BuildContext context,
    String targetLanguage,
  ) async {
    try {
      final decks = await DeckLoader.loadDecks();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage,
            decks: decks,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading decks: $e')));
    }
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
            LanguageOptionButton(
              text: "Magyar",
              color: Colors.red.shade700,
              emoji: "🇭🇺",
              onTap: () => _selectTargetLanguage(context, "hungarian"),
            ),
            // Add more target languages here
          ],
        ),
      ),
    );
  }
}
