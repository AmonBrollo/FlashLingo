import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';

import '../models/flashcard.dart';
import 'review_screen.dart';
import 'add_flashcard_screen.dart';
import '../utils/ui_strings.dart';
import '../utils/usage_limiter.dart';

class FlashcardScreen extends StatefulWidget {
  final String baseLanguage;
  final List<Flashcard> flashcards;

  const FlashcardScreen({
    super.key,
    required this.baseLanguage,
    required this.flashcards,
  });

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
    flashcards = widget.flashcards;
  }

  final UsageLimiter limiter = UsageLimiter();

  void _nextCard() async {
    final allowed = await limiter.canStudy();

    if (!allowed) {
      final remaining = await limiter.timeUntilReset();
      final minutes = remaining.inMinutes & 60;
      final hours = remaining.inHours;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Limit reached"),
          content: Text(
            "You have studied 30 flashcards.\nCome back in ${hours}h ${minutes}m",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    await limiter.markStudied();

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
                    baseLanguage: widget.baseLanguage,
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
            ? Text(
                UiStrings.finishedDeckText(widget.baseLanguage),
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
                            child: Stack(
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
                                      : (flashcard.imagePath != null
                                            ? Image.file(
                                                File(flashcard.imagePath!),
                                                width: 250,
                                                height: 250,
                                                fit: BoxFit.cover,
                                              )
                                            : Text(
                                                widget.baseLanguage ==
                                                        "portuguese"
                                                    ? flashcard.portuguese
                                                    : flashcard.english,
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )),
                                ),

                                if (flashcard.imagePath == null)
                                  Positioned(
                                    bottom: 40,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      widget.baseLanguage == "portuguese"
                                          ? "Nenhuma imagem ainda"
                                          : "No image yet",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.black54,
                                    ),
                                    tooltip: widget.baseLanguage == 'portuguese'
                                        ? 'Adicionar imagen'
                                        : 'Add image',
                                    onPressed: changeCurrentImage,
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
