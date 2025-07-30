import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class AddFlashcardScreen extends StatefulWidget {
  final Function(Flashcard) onAdd;

  const AddFlashcardScreen({super.key, required this.onAdd});

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final TextEditingController englishController = TextEditingController();
  final TextEditingController hungarianController = TextEditingController();

  void submit() {
    if (englishController.text.trim().isEmpty ||
        hungarianController.text.trim().isEmpty)
      return;

    final newFlashcard = Flashcard(
      english: englishController.text.trim(),
      hungarian: hungarianController.text.trim(),
      imagePath: null,
    );

    widget.onAdd(newFlashcard);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Flashcard'),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: englishController,
              decoration: const InputDecoration(
                labelText: 'Enter English word',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hungarianController,
              decoration: const InputDecoration(
                labelText: 'Enter Hungarian word',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              child: const Text("Add Flashcard"),
            ),
          ],
        ),
      ),
    );
  }
}
