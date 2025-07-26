import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FlashcardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Flashcard {
  final String imagePath;
  final String word;
  final bool isAsset;

  Flashcard({required this.imagePath, required this.word, this.isAsset = true});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      imagePath: json['imagePath'],
      word: json['word'],
      isAsset: true,
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Flashcard> flashcards = [];
  int currentIndex = 0;
  bool isFlipped = false;

  Future<void> loadFlashcards() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/flashcards.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      flashcards = jsonData.map((item) => Flashcard.fromJson(item)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadFlashcards();
  }

  void flipCard() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  void nextCard() {
    if (currentIndex < flashcards.length - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
      });
    }
  }

  void prevCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isFlipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (flashcards.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final flashcard = flashcards[currentIndex];

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Flashlingo'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: flipCard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isFlipped
                  ? Text(
                      flashcard.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : flashcard.isAsset
                  ? Image.asset(
                      flashcard.imagePath,
                      fit: BoxFit.cover,
                      width: 250,
                      height: 250,
                    )
                  : Image.file(
                      File(flashcard.imagePath),
                      fit: BoxFit.cover,
                      width: 250,
                      height: 250,
                    ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: prevCard,
                child: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: nextCard,
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFlashcardScreen(
                onAdd: (newCard) {
                  setState(() {
                    flashcards.add(newCard);
                    currentIndex = flashcards.length - 1;
                    isFlipped = false;
                  });
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddFlashcardScreen extends StatefulWidget {
  final Function(Flashcard) onAdd;

  const AddFlashcardScreen({super.key, required this.onAdd});

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final TextEditingController wordController = TextEditingController();
  File? imageFile;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  void submit() {
    if (imageFile != null && wordController.text.isNotEmpty) {
      final newFlashcard = Flashcard(
        imagePath: imageFile!.path,
        word: wordController.text.trim(),
        isAsset: false,
      );

      widget.onAdd(newFlashcard);
      Navigator.pop(context);
    }
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
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover)
                    : const Center(child: Text("Tap to pick image")),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: wordController,
              decoration: const InputDecoration(labelText: 'Enter word'),
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
