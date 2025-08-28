import 'package:flutter/material.dart';
import 'base_language_selector_screen.dart';

class LanguageSetupFlow extends StatelessWidget {
  const LanguageSetupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    // Start the language setup flow by showing the base language selector
    return const BaseLanguageSelectorScreen();
  }
}
