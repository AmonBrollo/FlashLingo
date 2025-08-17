import 'package:flutter/material.dart';
import 'deck_selector_screen.dart';
import '../services/deck_loader.dart';
import '../utils/ui_strings.dart';
import '../widgets/language_option_button.dart';

class TargetLanguageSelectorScreen extends StatefulWidget {
  final String baseLanguage;
  const TargetLanguageSelectorScreen({super.key, required this.baseLanguage});

  @override
  State<TargetLanguageSelectorScreen> createState() =>
      _TargetLanguageSelectorScreenState();
}

class _TargetLanguageSelectorScreenState
    extends State<TargetLanguageSelectorScreen> {
  void _selectTargetLanguage(String targetLanguage) async {
    try {
      final decks = await DeckLoader.loadDecks();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: widget.baseLanguage,
            targetLanguage: targetLanguage,
            decks: decks,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
        title: Text(UiStrings.selectTargetLanguage(widget.baseLanguage)),
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
              onTap: () => _selectTargetLanguage("hungarian"),
            ),
            // Add more target languages here
          ],
        ),
      ),
    );
  }
}
