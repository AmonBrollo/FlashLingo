import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  final String topicKey;
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
  bool _isFlipped = false;
  bool _finishedDeck = false;
  bool _limitReached = false;
  int _currentIndex = 0;
  double _dragDx = 0.0;
  late List<Flashcard> _flashcards;

  final UsageLimiter _limiter = UsageLimiter();
  final RepetitionService _repetitionService = RepetitionService();

  Future<void> loadFlashcardsFromAssets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/flashcards.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      _flashcards = jsonData.map((item) => Flashcard.fromJson(item)).toList();
      for (final card in _flashcards) {
        _repetitionService.getProgress(card);
      }
    });
  }

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
    });
    _checkInitialLimit();
  }

  Future<void> _checkInitialLimit() async {
    final allowed = await _limiter.canStudy();
    if (!allowed) {
      setState(() {
        _limitReached = true;
      });
    }
  }

  void _nextCard() async {
    final allowed = await _limiter.canStudy();

    if (!allowed) {
      setState(() {
        _limitReached = true;
        _isFlipped = false;
        _dragDx = 0.0;
      });
      return;
    }

    await _limiter.markStudied();

    setState(() {
      final reviewState = context.read<ReviewState>();

      final swipedThisSession = <Flashcard>{
        ...reviewState.remembered,
        ...reviewState.forgotten,
      };

      final remainingCards = _flashcards
          .where((card) => !swipedThisSession.contains(card))
          .toList();

      if (remainingCards.isNotEmpty) {
        final dueCards = _repetitionService.dueCards(remainingCards);

        if (dueCards.isNotEmpty) {
          _currentIndex = _flashcards.indexOf(remainingCards.first);
        } else {
          final newCards = _repetitionService.newCards(remainingCards);

          if (newCards.isNotEmpty) {
            _currentIndex = _flashcards.indexOf(newCards.first);
          } else {
            _currentIndex = _flashcards.indexOf(remainingCards.first);
          }
        }
      } else {
        _finishedDeck = true;
      }

      _isFlipped = false;
      _dragDx = 0.0;
    });
  }

  Future<void> _changeCurrentImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        final current = _flashcards[_currentIndex];
        _flashcards[_currentIndex] = Flashcard(
          translations: Map<String, String>.from(current.translations),
          imagePath: pickedFile.path,
        );
      });
    }
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFlashcardScreen(
                onAdd: (newCard) {
                  setState(() {
                    _flashcards.add(newCard);
                    _currentIndex = _flashcards.length - 1;
                    _isFlipped = false;
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
            if (!_limitReached && !_finishedDeck) {
              setState(() {
                _dragDx += details.delta.dx;
              });
            }
          },
          onPanEnd: (details) {
            if (!_limitReached && !_finishedDeck) {
              if (_dragDx > 100) {
                final currentCard = _flashcards[_currentIndex];
                _repetitionService.markRemembered(currentCard);
                context.read<ReviewState>().addCard(currentCard);
                _nextCard();
              } else if (_dragDx < -100) {
                final currentCard = _flashcards[_currentIndex];
                _repetitionService.markForgotten(currentCard);
                context.read<ReviewState>().addForgottenCard(currentCard);
                _nextCard();
              }
              setState(() {
                _dragDx = 0.0;
              });
            }
          },
          onTap: () {
            if (!_limitReached && !_finishedDeck) {
              setState(() {
                _isFlipped = !_isFlipped;
              });
            }
          },
          child: _buildCardContent(displayName),
        ),
      ),
    );
  }

  Widget _buildCardContent(String displayName) {
    if (_limitReached) {
      return FutureBuilder<Duration>(
        future: _limiter.timeUntilReset(),
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
    } else if (_finishedDeck) {
      return FinishedDeckCard(
        message: UiStrings.finishedDeckText(widget.baseLanguage),
      );
    } else {
      final currentCard = _flashcards[_currentIndex];
      return GestureDetector(
        onPanUpdate: (details) {
          if (!_limitReached && !_finishedDeck) {
            setState(() {
              _dragDx += details.delta.dx;
            });
          }
        },
        onPanEnd: (details) {
          if (!_limitReached && !_finishedDeck) {
            if (_dragDx > 100) {
              _repetitionService.markRemembered(currentCard);
              context.read<ReviewState>().addCard(currentCard);
              _nextCard();
            } else if (_dragDx < -100) {
              _repetitionService.markForgotten(currentCard);
              context.read<ReviewState>().addForgottenCard(currentCard);
              _nextCard();
            }
            setState(() {
              _dragDx = 0.0;
            });
          }
        },
        onTap: () {
          if (!_limitReached && !_finishedDeck) {
            setState(() {
              _isFlipped = !_isFlipped;
            });
          }
        },
        child: FlashcardView(
          flashcard: currentCard,
          progress: _repetitionService.getProgress(currentCard),
          isFlipped: _isFlipped,
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          dragDx: _dragDx,
          onFlip: () {
            setState(() => _isFlipped = !_isFlipped);
          },
          onAddImage: _changeCurrentImage,
          onRemembered: () {
            _repetitionService.markRemembered(currentCard);
            context.read<ReviewState>().addCard(currentCard);
            _nextCard();
          },
          onForgotten: () {
            _repetitionService.markForgotten(currentCard);
            context.read<ReviewState>().addForgottenCard(currentCard);
            _nextCard();
          },
        ),
      );
    }
  }
}
