import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deck_selector_screen.dart';
import '../services/deck_loader.dart';
import '../services/tutorial_service.dart';
import '../services/ui_language_provider.dart';
import '../widgets/language_option_button.dart';
import '../l10n/language.dart';

class TargetLanguageSelectorScreen extends StatelessWidget {
  final String baseLanguage;
  const TargetLanguageSelectorScreen({super.key, required this.baseLanguage});

  void _selectTargetLanguage(
    BuildContext context,
    String targetLanguage,
  ) async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    try {
      final decks = await DeckLoader.loadDecks();

      if (!context.mounted) return;

      final shouldShowTutorial = await TutorialService.shouldShowTutorial();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage,
            decks: decks,
            showTutorial: shouldShowTutorial,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${loc.errorLoadingDecks}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    
    // Get available target languages based on the base language
    final availableTargets = AppLanguages.getAvailableTargetLanguages(baseLanguage);
    
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Text(loc.selectTargetLanguage),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: availableTargets.map((language) {
            // Choose a color based on the language
            Color color;
            switch (language.code) {
              case 'hu':
                color = Colors.red.shade700;
                break;
              case 'es':
                color = Colors.amber.shade700;
                break;
              case 'en':
                color = Colors.blue.shade700;
                break;
              case 'pt':
                color = Colors.green.shade700;
                break;
              default:
                color = Colors.grey.shade700;
            }
            
            return LanguageOptionButton(
              text: language.name,
              color: color,
              emoji: language.flag,
              onTap: () => _selectTargetLanguage(context, language.legacyCode),
            );
          }).toList(),
        ),
      ),
    );
  }
}