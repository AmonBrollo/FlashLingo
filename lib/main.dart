import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/base_language_selector_screen.dart';
import '/services/review_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReviewState(),
      child: const FlashLango(),
    ),
  );
}

class FlashLango extends StatelessWidget {
  const FlashLango({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BaseLanguageSelectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
