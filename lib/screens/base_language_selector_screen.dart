import 'package:flutter/material.dart';
import 'target_language_selector_screen.dart';
import '../widgets/language_option_button.dart';

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
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text("Choose Base Language"),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LanguageOptionButton(
            text: "Português",
            color: Colors.green.shade700,
            emoji: "🇧🇷",
            onTap: () => _selectBaseLanguage(context, "portuguese"),
          ),
          LanguageOptionButton(
            text: "English",
            color: Colors.blue.shade700,
            emoji: "🇬🇧",
            onTap: () => _selectBaseLanguage(context, "english"),
          ),
        ],
      ),
    );
  }
}
