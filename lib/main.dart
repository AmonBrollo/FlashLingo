import 'package:flutter/material.dart';
import 'screens/language_selector_screen.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LanguageSelectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
