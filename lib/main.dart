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
  final String english;
  final String hungarian;
  final String? imagePath;

  Flashcard({
    required this.english,
    required this.hungarian,
    required this.imagePath,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      english: json['english'],
      hungarian: json['hungarian'],
      imagePath: null,
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
  List<Flashcard> remembered = [];
  List<Flashcard> forgotten = [];

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

  Future<void> changeCurrentImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        flashcards[currentIndex] = Flashcard(
          english: flashcards[currentIndex].english,
          hungarian: flashcards[currentIndex].hungarian,
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
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Dismissible(
            key: ValueKey(currentIndex),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              setState(() {
                if (direction == DismissDirection.startToEnd) {
                  remembered.add(flashcards[currentIndex]);
                } else if (direction == DismissDirection.endToStart) {
                  forgotten.add(flashcards[currentIndex]);
                }
                if (currentIndex < flashcards.length - 1) {
                  currentIndex++;
                } else {
                  currentIndex = 0;
                }
                isFlipped = false;
              });
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isFlipped = !isFlipped;
                });
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
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
                                  flashcard.english,
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
                                        'No image yet. \n Tap ✏️ to add one.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 18),
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
                            icon: const Icon(Icons.edit, color: Colors.black87),
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
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: prevCard,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: nextCard,
              ),
            ],
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
  final TextEditingController englishController = TextEditingController();
  final TextEditingController hungarianController = TextEditingController();

  void submit() {
    if (englishController.text.trim().isEmpty) return;

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
