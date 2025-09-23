import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/flashcard.dart';
import '../services/repetition_service.dart';
import '../services/review_state.dart';
import '../services/deck_loader.dart';
import '../services/local_image_service.dart';
import '../utils/ui_strings.dart';
import '../utils/topic_names.dart';
import '../utils/usage_limiter.dart';
import '../widgets/flashcard_view.dart';
import '../widgets/finished_deck_card.dart';
import '../widgets/limit_reached_card.dart';
import 'add_flashcard_screen.dart';
import 'review_screen.dart';
import 'profile_screen.dart';
import 'deck_selector_screen.dart';

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
  bool _isInitializing = true;

  final UsageLimiter _limiter = UsageLimiter();
  final RepetitionService _repetitionService = RepetitionService();

  final Set<Flashcard> _swipedThisSession = {};

  @override
  void initState() {
    super.initState();
    _flashcards = List.from(widget.flashcards); // Make a mutable copy
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      // Initialize the repetition service and preload progress
      await _repetitionService.initialize();
      await _repetitionService.preloadProgress(_flashcards);

      // Load local images for all flashcards
      await _loadLocalImages();

      // Set current deck in review state
      if (mounted) {
        context.read<ReviewState>().setCurrentDeck(widget.topicKey);
      }

      // Check usage limits
      await _checkInitialLimit();

      // Find the best starting card (prioritize due cards, then new cards)
      _selectOptimalStartingCard();
    } catch (e) {
      print('Error initializing flashcard screen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadLocalImages() async {
    try {
      final updatedFlashcards = <Flashcard>[];

      for (final card in _flashcards) {
        final imagePath = await LocalImageService.getCardImagePath(card);
        if (imagePath != null) {
          updatedFlashcards.add(
            card.copyWithImage(imagePath: imagePath, hasLocalImage: true),
          );
        } else {
          updatedFlashcards.add(card);
        }
      }

      if (mounted) {
        setState(() {
          _flashcards = updatedFlashcards;
        });
      }
    } catch (e) {
      print('Error loading local images: $e');
    }
  }

  void _selectOptimalStartingCard() {
    final dueCards = _repetitionService.dueCards(_flashcards);
    if (dueCards.isNotEmpty) {
      _currentIndex = _flashcards.indexOf(dueCards.first);
      return;
    }

    final newCards = _repetitionService.newCards(_flashcards);
    if (newCards.isNotEmpty) {
      _currentIndex = _flashcards.indexOf(newCards.first);
      return;
    }

    // If no due or new cards, start with the first card
    _currentIndex = 0;
  }

  Future<void> _checkInitialLimit() async {
    final allowed = await _limiter.canStudy();
    if (!allowed) {
      setState(() {
        _limitReached = true;
      });
    }
  }

  Future<void> loadFlashcardsFromAssets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/flashcards.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      _flashcards = jsonData.map((item) => Flashcard.fromJson(item)).toList();
      // Initialize progress for all cards
      for (final card in _flashcards) {
        _repetitionService.getProgress(card);
      }
    });

    // Load local images after updating flashcards
    await _loadLocalImages();
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
      final remainingCards = _flashcards
          .where((card) => !_swipedThisSession.contains(card))
          .toList();

      if (remainingCards.isNotEmpty) {
        final dueCards = _repetitionService.dueCards(remainingCards);
        if (dueCards.isNotEmpty) {
          _currentIndex = _flashcards.indexOf(dueCards.first);
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
    final currentCard = _flashcards[_currentIndex];

    try {
      // Show image source options
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Delete old image if it exists
      if (currentCard.hasLocalImage) {
        await LocalImageService.deleteCardImage(currentCard);
      }

      // Save the new image locally
      final savedImagePath = await LocalImageService.saveCardImage(
        currentCard,
        pickedFile.path,
      );

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (savedImagePath != null) {
        // Update the flashcard with the new image
        final updatedCard = currentCard.copyWithImage(
          imagePath: savedImagePath,
          hasLocalImage: true,
        );

        setState(() {
          _flashcards[_currentIndex] = updatedCard;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog if it's showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error changing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeCurrentImage() async {
    final currentCard = _flashcards[_currentIndex];

    if (!currentCard.hasLocalImage) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalImageService.deleteCardImage(currentCard);

      final updatedCard = currentCard.copyWithoutImage();
      setState(() {
        _flashcards[_currentIndex] = updatedCard;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _goToDeckSelector() async {
    try {
      final decks = await DeckLoader.loadDecks();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: widget.baseLanguage,
            targetLanguage: widget.targetLanguage,
            decks: decks,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading decks: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      case 'profile':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case 'select_deck':
        await _goToDeckSelector();
        break;
    }
  }

  void _handleSwipe(Flashcard card, bool remembered) {
    _swipedThisSession.add(card);
    if (remembered) {
      _repetitionService.markRemembered(card);
      final reviewState = context.read<ReviewState>();
      reviewState.addCard(card);

      if (widget.topicKey == 'forgotten') {
        reviewState.removeForgottenCard(card);
      }
    } else {
      _repetitionService.markForgotten(card);
      context.read<ReviewState>().addForgottenCard(card);
    }

    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator during initialization
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.brown[50],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
              SizedBox(height: 16),
              Text('Loading progress...'),
            ],
          ),
        ),
      );
    }

    if (_flashcards.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = TopicNames.getName(
      widget.topicKey,
      widget.baseLanguage,
    );

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToDeckSelector,
        ),
        title: Row(
          children: [
            const Text('Flashlango'),
            const Spacer(),
            Consumer<ReviewState>(
              builder: (context, reviewState, child) {
                final revealed = reviewState.getRevealedCount(widget.topicKey);
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
              PopupMenuItem(
                value: 'select_deck',
                child: Row(
                  children: [
                    Icon(Icons.view_module, size: 20),
                    SizedBox(width: 8),
                    Text('Select Deck'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, size: 20),
                    SizedBox(width: 8),
                    Text('Review'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
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
              setState(() => _dragDx += details.delta.dx);
            }
          },
          onPanEnd: (details) {
            if (!_limitReached && !_finishedDeck) {
              final currentCard = _flashcards[_currentIndex];
              if (_dragDx > 100) {
                _handleSwipe(currentCard, true);
              } else if (_dragDx < -100) {
                _handleSwipe(currentCard, false);
              }
              setState(() => _dragDx = 0.0);
            }
          },
          onTap: () {
            if (!_limitReached && !_finishedDeck) {
              setState(() => _isFlipped = !_isFlipped);
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
      return FlashcardView(
        flashcard: currentCard,
        progress: _repetitionService.getProgress(currentCard),
        isFlipped: _isFlipped,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
        dragDx: _dragDx,
        onFlip: () => setState(() => _isFlipped = !_isFlipped),
        onAddImage: _changeCurrentImage,
        onRemoveImage: _removeCurrentImage,
        onRemembered: () => _handleSwipe(currentCard, true),
        onForgotten: () => _handleSwipe(currentCard, false),
      );
    }
  }
}
