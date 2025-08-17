import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'review_screen.dart';
import 'add_flashcard_screen.dart';
import '../models/flashcard.dart';
import '../services/spaced_repetition_service.dart';
import '../utils/ui_strings.dart';
import '../utils/usage_limiter.dart';
import '../widgets/limit_reached_card.dart';
import '../widgets/finished_deck_card.dart';
import '../widgets/flashcard_view.dart';

class FlashcardScreen extends StatefulWidget {
  final String baseLanguage;
  final String targetLanguage;
  final List<Flashcard> flashcards;

  const FlashcardScreen({
    super.key,
    required this.baseLanguage,
    required this.targetLanguage,
    required this.flashcards,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  bool isFlipped = false;
  bool finishedDeck = false;
  bool limitReached = false;
  int currentIndex = 0;
  double _dragDx = 0.0;
  List<Flashcard> flashcards = [];
  List<Flashcard> remembered = [];
  List<Flashcard> forgotten = [];

  final UsageLimiter limiter = UsageLimiter();

  final SpacedRepetitionService repetitionService = SpacedRepetitionService();

  Future<void> loadFlashcards() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/flashcards.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      flashcards = jsonData.map((item) => Flashcard.fromJson(item)).toList();

      for (final card in flashcards) {
        repetitionService.getProgress(card);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    flashcards = widget.flashcards;
    loadFlashcards();
  }

  void _nextCard() async {
    final allowed = await limiter.canStudy();

    if (!allowed) {
      setState(() {
        limitReached = true;
        isFlipped = false;
        _dragDx = 0.0;
      });
      return;
    }

    await limiter.markStudied();

    setState(() {
      final dueFlashcards = repetitionService.dueCards(flashcards);

      if (dueFlashcards.isNotEmpty) {
        final next = dueFlashcards.firstWhere(
          (card) => flashcards.indexOf(card) != currentIndex,
          orElse: () => dueFlashcards.first,
        );
        currentIndex = flashcards.indexOf(next);
      } else if (currentIndex < flashcards.length - 1) {
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
          translations: Map<String, String>.from(current.translations),
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

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Flashlango'),
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
                    targetLanguage: widget.targetLanguage,
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
                targetLanguage: widget.targetLanguage,
              ),
            ),
          );
        },
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: GestureDetector(
          onPanUpdate: (details) {
            if (!limitReached && !finishedDeck) {
              setState(() {
                _dragDx += details.delta.dx;
              });
            }
          },
          onPanEnd: (details) {
            if (!limitReached && !finishedDeck) {
              if (_dragDx > 100) {
                remembered.add(flashcards[currentIndex]);
                _nextCard();
              } else if (_dragDx < -100) {
                forgotten.add(flashcards[currentIndex]);
                _nextCard();
              }
              setState(() {
                _dragDx = 0.0;
              });
            }
          },
          onTap: () {
            if (!limitReached && !finishedDeck) {
              setState(() {
                isFlipped = !isFlipped;
              });
            }
          },
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (limitReached) {
      return FutureBuilder<Duration>(
        future: limiter.timeUntilReset(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return LimitReachedCard(
            timeRemaining: snapshot.data!,
            baseLanguage: widget.baseLanguage,
          );
        },
      );
    } else if (finishedDeck) {
      return FinishedDeckCard(
        message: UiStrings.finishedDeckText(widget.baseLanguage),
      );
    } else {
      return FlashcardView(
        flashcard: flashcards[currentIndex],
        isFlipped: isFlipped,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
        dragDx: _dragDx,
        onFlip: () => setState(() => isFlipped = !isFlipped),
        onAddImage: changeCurrentImage,
        onRemembered: () {
          repetitionService.markRemembered(flashcards[currentIndex]);
          remembered.add(flashcards[currentIndex]);
          _nextCard();
        },
        onForgotten: () {
          repetitionService.markForgotten(flashcards[currentIndex]);
          forgotten.add(flashcards[currentIndex]);
          _nextCard();
        },
      );
    }
  }
}
