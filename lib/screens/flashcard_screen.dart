import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/flashcard.dart';
import '../services/repetition_service.dart';
import '../services/review_state.dart';
import '../utils/ui_strings.dart';
import '../utils/topic_names.dart';
import '../utils/usage_limiter.dart';
import '../widgets/flashcard_view.dart';
import '../widgets/finished_deck_card.dart';
import '../widgets/limit_reached_card.dart';
import 'add_flashcard_screen.dart';
import 'review_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final String baseLanguage;
  final String targetLanguage;
  final String topicKey; // changed from deckTopic
  final List<Flashcard> flashcards;

  const FlashcardScreen({
    super.key,
    required this.baseLanguage,
    required this.targetLanguage,
    required this.topicKey,
    required this.flashcards,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<Flashcard> _flashcards;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _limitReached = false;

  final RepetitionService _repetitionService = RepetitionService();
  final UsageLimiter _limiter = UsageLimiter();

  @override
  void initState() {
    super.initState();
    _flashcards = widget.flashcards;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final displayName = TopicNames.getName(
        widget.topicKey,
        widget.baseLanguage,
      );
      context.read<ReviewState>().setCurrentDeck(displayName);
      _checkLimit();
    });
  }

  Future<void> _checkLimit() async {
    final allowed = await _limiter.canStudy();
    if (!allowed) setState(() => _limitReached = true);
  }

  void _nextCard({bool remembered = true}) async {
    final reviewState = context.read<ReviewState>();
    final allowed = await _limiter.canStudy();
    if (!allowed) {
      setState(() => _limitReached = true);
      return;
    }

    await _limiter.markStudied();
    final currentCard = _flashcards[_currentIndex];

    if (remembered) {
      _repetitionService.markRemembered(currentCard);
      reviewState.addCard(currentCard);
    } else {
      _repetitionService.markForgotten(currentCard);
    }

    setState(() {
      _isFlipped = false;
      if (_currentIndex < _flashcards.length - 1) _currentIndex++;
    });
  }

  Future<void> _changeCurrentImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    setState(() {
      final current = _flashcards[_currentIndex];
      _flashcards[_currentIndex] = Flashcard(
        translations: Map<String, String>.from(current.translations),
        imagePath: pickedFile.path,
      );
    });
  }

  void _onMenuSelected(String value) async {
    switch (value) {
      case 'review':
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
        break;
      case 'login':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
      case 'profile':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flashcards.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final finishedDeck = _currentIndex >= _flashcards.length;
    final displayName = TopicNames.getName(
      widget.topicKey,
      widget.baseLanguage,
    );

    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Flashlango'),
            const Spacer(),
            Consumer<ReviewState>(
              builder: (context, reviewState, child) {
                final revealed = reviewState.getRevealedCount(displayName);
                final total = _flashcards.length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$revealed/$total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.brown,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'review', child: Text('Review')),
              if (isAnonymous)
                const PopupMenuItem(value: 'login', child: Text('Login'))
              else
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFlashcardScreen(
                baseLanguage: widget.baseLanguage,
                targetLanguage: widget.targetLanguage,
                onAdd: (newCard) {
                  setState(() {
                    _flashcards.add(newCard);
                    _currentIndex = _flashcards.length - 1;
                    _isFlipped = false;
                  });
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Center(child: _buildCardContent(finishedDeck)),
    );
  }

  Widget _buildCardContent(bool finishedDeck) {
    if (_limitReached) {
      return FutureBuilder<Duration>(
        future: _limiter.timeUntilReset(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
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
      final currentCard = _flashcards[_currentIndex];
      return FlashcardView(
        flashcard: currentCard,
        progress: _repetitionService.getProgress(currentCard),
        isFlipped: _isFlipped,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
        dragDx: 0.0,
        onFlip: () => setState(() => _isFlipped = !_isFlipped),
        onAddImage: _changeCurrentImage,
        onRemembered: () => _nextCard(remembered: true),
        onForgotten: () => _nextCard(remembered: false),
      );
    }
  }
}
