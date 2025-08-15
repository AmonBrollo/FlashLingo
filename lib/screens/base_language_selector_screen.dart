import 'package:flutter/material.dart';
import '../screens/target_language_selector_screen.dart';

class BaseLanguageSelectorScreen extends StatelessWidget {
  const BaseLanguageSelectorScreen({super.key});

  void _selectBaseLanguage(BuildContext context, String baseLanguage) {
    Navigator.pushReplacement(
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectBaseLanguage(context, "portuguese"),
              child: const Text("Português"),
            ),
            ElevatedButton(
              onPressed: () => _selectBaseLanguage(context, "english"),
              child: const Text("English"),
            ),
            // Add more base languages here
          ],
        ),
      ),
    );
  }
}
