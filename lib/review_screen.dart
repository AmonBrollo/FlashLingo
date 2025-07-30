import 'main.dart';
import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final List<Flashcard> remembered;
  final List<Flashcard> forgotten;

  const ReviewScreen({
    super.key,
    required this.remembered,
    required this.forgotten,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Flashcards"),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // ✅ Remembered column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Remembered ✅",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: remembered.length,
                      itemBuilder: (context, index) {
                        final card = remembered[index];
                        return Card(
                          child: ListTile(
                            title: Text(card.english),
                            subtitle: Text(card.hungarian),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ❌ Forgotten column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Forgotten ❌",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: forgotten.length,
                      itemBuilder: (context, index) {
                        final card = forgotten[index];
                        return Card(
                          child: ListTile(
                            title: Text(card.english),
                            subtitle: Text(card.hungarian),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
