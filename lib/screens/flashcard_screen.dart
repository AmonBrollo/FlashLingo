import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'review_screen.dart';
import 'add_flashcard_screen.dart';
import '../models/flashcard.dart';
import '../services/repetition_service.dart';
import '../services/review_state.dart';
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

  final UsageLimiter limiter = UsageLimiter();
  final RepetitionService repetitionService = RepetitionService();

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
      final swipedCards = context.read<ReviewState>().remembered;

      final dueFlashcards = repetitionService
          .dueCards(flashcards)
          .where((card) => !swipedCards.contains(card))
          .toList();

      if (dueFlashcards.isNotEmpty) {
        currentIndex = flashcards.indexOf(dueFlashcards.first);
      } else {
        final newCards = repetitionService
            .dueCards(flashcards)
            .where((card) => !swipedCards.contains(card))
            .toList();
        if (newCards.isNotEmpty) {
          currentIndex = flashcards.indexOf(newCards.first);
        } else {
          finishedDeck = true;
        }
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
              final remembered = context.read<ReviewState>().remembered;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    cards: remembered,
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
                context.read<ReviewState>().addCard(flashcards[currentIndex]);
                _nextCard();
              } else if (_dragDx < -100) {
                /// to do: add a ReviewState.addForgotten
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
        progress: repetitionService.getProgress(flashcards[currentIndex]),
        isFlipped: isFlipped,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
        dragDx: _dragDx,
        onFlip: () => setState(() => isFlipped = !isFlipped),
        onAddImage: changeCurrentImage,
        onRemembered: () {
          final currentCard = flashcards[currentIndex];
          repetitionService.markRemembered(currentCard);
          context.read<ReviewState>().addCard(currentCard);
          _nextCard();
        },
        onForgotten: () {
          repetitionService.markForgotten(flashcards[currentIndex]);

          /// to do: add a ReviewState.addForgotten
          _nextCard();
        },
      );
    }
  }
}
