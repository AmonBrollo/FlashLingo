import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'target_language_selector_screen.dart';
import '../widgets/language_option_button.dart';
import '../services/ui_language_provider.dart';
import '../l10n/language.dart';

class BaseLanguageSelectorScreen extends StatelessWidget {
  const BaseLanguageSelectorScreen({super.key});

  void _selectBaseLanguage(BuildContext context, String baseLanguage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TargetLanguageSelectorScreen(baseLanguage: baseLanguage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Text(loc.chooseBaseLanguage),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LanguageOptionButton(
            text: AppLanguages.portuguese.name,
            color: Colors.green.shade700,
            emoji: AppLanguages.portuguese.flag,
            onTap: () => _selectBaseLanguage(context, "portuguese"),
          ),
          LanguageOptionButton(
            text: AppLanguages.english.name,
            color: Colors.blue.shade700,
            emoji: AppLanguages.english.flag,
            onTap: () => _selectBaseLanguage(context, "english"),
          ),
        ],
      ),
    );
  }
}