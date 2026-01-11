import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/flashcard.dart';
import '../services/repetition_service.dart';
import '../services/review_state.dart';
import '../services/deck_loader.dart';
import '../services/local_image_service.dart';
import '../services/ui_language_provider.dart';
import '../utils/topic_names.dart';
import '../utils/usage_limiter.dart';
import '../widgets/flashcard_view.dart';
import '../widgets/finished_deck_card.dart';
import '../widgets/limit_reached_card.dart';
import 'review_screen.dart';
import 'profile_screen.dart';
import 'deck_selector_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final String baseLanguage;
  final String targetLanguage;
  final String topicKey;
  final List<Flashcard> flashcards;
  final bool showTutorial;

  const FlashcardScreen({
    super.key,
    required this.baseLanguage,
    required this.targetLanguage,
    required this.topicKey,
    required this.flashcards,
    this.showTutorial = false,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _finishedDeck = false;
  bool _limitReached = false;
  int _currentIndex = 0;
  double _dragDx = 0.0;
  late List<Flashcard> _flashcards;
  bool _isInitializing = true;
  
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AudioPlayer _audioPlayer;

  final UsageLimiter _limiter = UsageLimiter();
  final RepetitionService _repetitionService = RepetitionService();
  final Set<Flashcard> _swipedThisSession = {};

  final GlobalKey _flashcardKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flashcards = List.from(widget.flashcards);
    _audioPlayer = AudioPlayer();
    
    // Set language context for repetition service
    _repetitionService.setLanguageContext(widget.baseLanguage, widget.targetLanguage);
    
    // Initialize flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    
    _initializeScreen();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      if (!_repetitionService.isCacheLoaded) {
        await _repetitionService.initialize(
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
        );
      }
      
      await _repetitionService.preloadProgress(
        _flashcards,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );
      await _loadLocalImages();

      if (mounted) {
        context.read<ReviewState>().setCurrentDeck(widget.topicKey);
      }

      await _checkInitialLimit();
      _selectOptimalStartingCard();
    } catch (e) {
      debugPrint('Error initializing flashcard screen: $e');
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
      debugPrint('Error loading local images: $e');
    }
  }

  void _selectOptimalStartingCard() {
    final dueCards = _repetitionService.dueCards(
      _flashcards,
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
    );
    if (dueCards.isNotEmpty) {
      _currentIndex = _flashcards.indexOf(dueCards.first);
      return;
    }

    final newCards = _repetitionService.newCards(
      _flashcards,
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
    );
    if (newCards.isNotEmpty) {
      _currentIndex = _flashcards.indexOf(newCards.first);
      return;
    }

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
      for (final card in _flashcards) {
        _repetitionService.getProgress(
          card,
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
        );
      }
    });

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
        final dueCards = _repetitionService.dueCards(
          remainingCards,
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
        );
        if (dueCards.isNotEmpty) {
          _currentIndex = _flashcards.indexOf(dueCards.first);
        } else {
          final newCards = _repetitionService.newCards(
            remainingCards,
            baseLanguage: widget.baseLanguage,
            targetLanguage: widget.targetLanguage,
          );
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

  Future<void> _playAudio() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    try {
      final currentCard = _flashcards[_currentIndex];
      
      final englishWord = currentCard.getTranslation('english');
      final audioFilename = Flashcard.getAudioFilename(widget.topicKey, englishWord);
      final audioPath = 'audio/$audioFilename.mp3';
      
      debugPrint('Attempting to play audio: $audioPath');
      debugPrint('English word: $englishWord');
      debugPrint('Topic: ${widget.topicKey}');
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.audioNotAvailableError}: $e')),
        );
      }
    }
  }

  Future<void> _changeCurrentImage() async {
    final loc = context.read<UiLanguageProvider>().loc;
    final currentCard = _flashcards[_currentIndex];

    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      if (currentCard.hasLocalImage) {
        await LocalImageService.deleteCardImage(currentCard);
      }

      final savedImagePath = await LocalImageService.saveCardImage(
        currentCard,
        pickedFile.path,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (savedImagePath != null) {
        final updatedCard = currentCard.copyWithImage(
          imagePath: savedImagePath,
          hasLocalImage: true,
        );

        setState(() {
          _flashcards[_currentIndex] = updatedCard;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.imageSavedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.failedToSaveImage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('Error changing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeCurrentImage() async {
    final loc = context.read<UiLanguageProvider>().loc;
    final currentCard = _flashcards[_currentIndex];

    if (!currentCard.hasLocalImage) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.removeImage),
        content: Text(loc.removeImageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.remove),
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
          SnackBar(
            content: Text(loc.imageRemoved),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _goToDeckSelector() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
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
          content: Text('${loc.errorLoadingDecks}: $e'),
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
      _repetitionService.markRemembered(
        card,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );
      final reviewState = context.read<ReviewState>();
      reviewState.addCard(card);

      if (widget.topicKey == 'forgotten') {
        reviewState.removeForgottenCard(card);
      }
    } else {
      _repetitionService.markForgotten(
        card,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );
      context.read<ReviewState>().addForgottenCard(card);
    }

    _nextCard();
  }

  void _handleButtonPress(bool remembered) async {
    final currentCard = _flashcards[_currentIndex];
    
    final targetDx = remembered ? 400.0 : -400.0;
    final frames = 10;
    final increment = targetDx / frames;
    
    for (int i = 0; i < frames; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (mounted) {
        setState(() {
          _dragDx += increment;
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    _handleSwipe(currentCard, remembered);
  }

  void _handleFlip() async {
    if (_flipController.isAnimating) return;
    
    _flipController.forward(from: 0.0).then((_) {
      _flipController.reset();
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isFlipped = !_isFlipped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.brown[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
              const SizedBox(height: 16),
              Text(loc.loadingProgress),
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
            Text(loc.flashLango),
            const Spacer(),
            Consumer<ReviewState>(
              builder: (context, reviewState, child) {
                final revealed = reviewState.getRevealedCount(widget.topicKey);
                final total = _flashcards.length;
                final cardsLeft = total - revealed;
                
                return Container(
                  key: _progressKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cardsLeft > 0 ? '$cardsLeft ${loc.left}' : loc.complete,
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
                    const Icon(Icons.view_module, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.selectDeck),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    const Icon(Icons.rate_review, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.review),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(loc.profile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_limitReached && !_finishedDeck)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() => _dragDx += details.delta.dx);
                },
                onPanEnd: (details) {
                  final currentCard = _flashcards[_currentIndex];
                  if (_dragDx > 100) {
                    _handleSwipe(currentCard, true);
                  } else if (_dragDx < -100) {
                    _handleSwipe(currentCard, false);
                  }
                  setState(() => _dragDx = 0.0);
                },
                onTap: () {
                  _handleFlip();
                },
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * 3.14159;
                    final isHalfway = _flipAnimation.value > 0.5;
                    
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: isHalfway
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(3.14159),
                              alignment: Alignment.center,
                              child: _buildCardContent(displayName),
                            )
                          : _buildCardContent(displayName),
                    );
                  },
                ),
              )
            else
              _buildCardContent(displayName),
            
            if (!_limitReached && !_finishedDeck) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      label: loc.forgot,
                      color: Colors.red,
                      onPressed: () {
                        _handleButtonPress(false);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.sync,
                      label: loc.flip,
                      color: Colors.grey,
                      onPressed: () {
                        _handleFlip();
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.check,
                      label: loc.remember,
                      color: Colors.green,
                      onPressed: () {
                        _handleButtonPress(true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 4,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
        message: context.read<UiLanguageProvider>().loc.finishedDeck,
      );
    } else {
      final currentCard = _flashcards[_currentIndex];
      return Container(
        key: _flashcardKey,
        child: FlashcardView(
          flashcard: currentCard,
          progress: _repetitionService.getProgress(
            currentCard,
            baseLanguage: widget.baseLanguage,
            targetLanguage: widget.targetLanguage,
          ),
          isFlipped: _isFlipped,
          baseLanguage: widget.baseLanguage,
          targetLanguage: widget.targetLanguage,
          dragDx: _dragDx,
          onFlip: () => setState(() => _isFlipped = !_isFlipped),
          onAddImage: _changeCurrentImage,
          onRemoveImage: _removeCurrentImage,
          onRemembered: () => _handleSwipe(currentCard, true),
          onForgotten: () => _handleSwipe(currentCard, false),
          onPlayAudio: _playAudio,
        ),
      );
    }
  }
}