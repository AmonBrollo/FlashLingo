import 'dart:io';
import 'dart:convert';
import 'package:flashlingo/screens/language_selector_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';

import 'models/flashcard.dart';
import 'screens/review_screen.dart';
import 'screens/add_flashcard_screen.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LanguageSelectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  final String baseLanguage;

  const FlashcardScreen({super.key, required this.baseLanguage});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Flashcard> flashcards = [];
  int currentIndex = 0;
  bool isFlipped = false;
  List<Flashcard> remembered = [];
  List<Flashcard> forgotten = [];
  double _dragDx = 0.0;
  bool finishedDeck = false;

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

  void _nextCard() {
    setState(() {
      if (currentIndex < flashcards.length - 1) {
        currentIndex++;
      } else {
        finishedDeck = true;
      }
      isFlipped = false;
      _dragDx = 0.0;
    });
  }

  Future<void> changeCurrentImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        final current = flashcards[currentIndex];
        flashcards[currentIndex] = Flashcard(
          english: current.english,
          portuguese: current.portuguese,
          hungarian: current.hungarian,
          imagePath: pickedFile.path,
        );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Review results',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    remembered: remembered,
                    forgotten: forgotten,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
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
                baseLanguage: widget.baseLanguage,
              ),
            ),
          );
        },
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: finishedDeck
            ? const Text(
                "🎉 You've gone through all the flashcards!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
                textAlign: TextAlign.center,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _dragDx += details.delta.dx;
                      });
                    },
                    onPanEnd: (details) {
                      if (_dragDx > 100) {
                        remembered.add(flashcards[currentIndex]);
                        _nextCard();
                      } else if (_dragDx < -100) {
                        forgotten.add(flashcards[currentIndex]);
                        _nextCard();
                      } else {
                        setState(() {
                          _dragDx = 0.0;
                        });
                      }
                    },
                    onTap: () {
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 30,
                          child: Opacity(
                            opacity: _dragDx > 0
                                ? (_dragDx / 150).clamp(0, 1).toDouble()
                                : 0,
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 80,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 30,
                          child: Opacity(
                            opacity: _dragDx < 0
                                ? (-_dragDx / 150).clamp(0, 1).toDouble()
                                : 0,
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 80,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(_dragDx, 0),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: isFlipped
                                      ? Text(
                                          flashcard.hungarian,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            Text(
                                              widget.baseLanguage ==
                                                      "portuguese"
                                                  ? flashcard.portuguese
                                                  : flashcard.english,
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            flashcard.imagePath != null
                                                ? Image.file(
                                                    File(flashcard.imagePath!),
                                                    width: 250,
                                                    height: 250,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Text(
                                                    'No image yet.\nTap ✏️ to add one.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.black87,
                                        ),
                                        tooltip: 'Add image',
                                        onPressed: changeCurrentImage,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
