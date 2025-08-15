import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../utils/ui_strings.dart';

class AddFlashcardScreen extends StatefulWidget {
  final Function(Flashcard) onAdd;
  final String baseLanguage;
  final String targetLanguage;

  const AddFlashcardScreen({
    super.key,
    required this.onAdd,
    required this.baseLanguage,
    required this.targetLanguage,
  });

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final baseController = TextEditingController();
  final targetController = TextEditingController();

  void submit() {
    if (baseController.text.trim().isEmpty ||
        targetController.text.trim().isEmpty) {
      return;
    }

    final newFlashcard = Flashcard(
      translations: {
        widget.baseLanguage: baseController.text.trim(),
        widget.targetLanguage: targetController.text.trim(),
      },
    );

    widget.onAdd(newFlashcard);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(UiStrings.addFlashcardTitle(widget.baseLanguage)),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: baseController,
              decoration: InputDecoration(
                labelText: widget.baseLanguage == "portuguese"
                    ? 'Digite a palavra em Português'
                    : 'Enter English word',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                labelText: UiStrings.addHungarianWord(widget.baseLanguage),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              child: Text(UiStrings.addFlashcardButton(widget.baseLanguage)),
            ),
          ],
        ),
      ),
    );
  }
}
