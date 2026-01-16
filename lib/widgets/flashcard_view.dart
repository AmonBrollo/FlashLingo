import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';
import '../services/ui_language_provider.dart';

class FlashcardView extends StatefulWidget {
  final Flashcard flashcard;
  final FlashcardProgress progress;
  final bool isFlipped;
  final String baseLanguage;
  final String targetLanguage;
  final double dragDx;
  final VoidCallback onFlip;
  final VoidCallback onAddImage;
  final VoidCallback? onRemoveImage;
  final VoidCallback onRemembered;
  final VoidCallback onForgotten;
  final VoidCallback onPlayAudio;

  const FlashcardView({
    super.key,
    required this.flashcard,
    required this.progress,
    required this.isFlipped,
    required this.baseLanguage,
    required this.targetLanguage,
    required this.dragDx,
    required this.onFlip,
    required this.onAddImage,
    this.onRemoveImage,
    required this.onRemembered,
    required this.onForgotten,
    required this.onPlayAudio,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Flip peek animation: 0 → 0.3 (peek) → 0 (back)
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_animationController);

    // Subtle scale: 1.0 → 1.02 → 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);

    // Start the periodic animation
    _startPeriodicAnimation();
  }

  void _startPeriodicAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted) {
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = MediaQuery.of(context).size.height * 0.5;

    final statusText = widget.progress.hasStarted
        ? loc.levelName(widget.progress.box)
        : loc.newCard;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 30,
          child: Opacity(
            opacity: widget.dragDx > 0 ? (widget.dragDx / 150).clamp(0, 1).toDouble() : 0,
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
            opacity: widget.dragDx < 0 ? (-widget.dragDx / 150).clamp(0, 1).toDouble() : 0,
            child: const Icon(Icons.cancel, color: Colors.red, size: 80),
          ),
        ),

        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(widget.dragDx, 0),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(_rotationAnimation.value),
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: cardWidth.clamp(280.0, 360.0),
                    height: cardHeight.clamp(360.0, 460.0),
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
                        // Status indicator
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.progress.hasStarted
                                  ? Colors.orange[200]
                                  : Colors.green[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Flip icon
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Opacity(
                            opacity: 0.3,
                            child: const Icon(Icons.sync, color: Colors.grey, size: 24),
                          ),
                        ),

                        // Main card content
                        Center(child: _buildCardContent(context)),

                        // No image text (only shown when not flipped and no image)
                        if (!widget.isFlipped && !widget.flashcard.hasLocalImage)
                          Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: Text(
                              loc.noImageYet,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),

                        // Image management buttons (ONLY ON FRONT)
                        if (!widget.isFlipped) _buildImageControls(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardContent(BuildContext context) {
    // Determine which translation to show
    final String cardText = widget.isFlipped
        ? widget.flashcard.getTranslation(widget.targetLanguage)
        : widget.flashcard.getTranslation(widget.baseLanguage);

    if (!widget.isFlipped && widget.flashcard.hasLocalImage && widget.flashcard.imagePath != null) {
      // Front side with image - no audio button here
      return _buildImageContent();
    } else if (widget.isFlipped) {
      // Back side (target language) - use Stack for precise positioning
      return SizedBox.expand(
        child: Stack(
          children: [
            // The word (absolutely centered)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  cardText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Audio button (positioned between center and bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.volume_up,
                    size: 28.0,
                    color: Colors.grey,
                  ),
                  onPressed: widget.onPlayAudio,
                  tooltip: 'Play audio',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Front side (base language) - no audio button, just text
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          cardText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildImageContent() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main image
            SizedBox(
              width: 250,
              height: 250,
              child: Image.file(
                File(widget.flashcard.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  final loc = context.read<UiLanguageProvider>().loc;
                  return Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.imageRemoved,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Text overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  widget.flashcard.getTranslation(widget.baseLanguage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageControls(BuildContext context) {
    final loc = context.read<UiLanguageProvider>().loc;
    
    if (widget.flashcard.hasLocalImage) {
      // Show edit and delete buttons when image exists
      return Positioned(
        bottom: 8,
        right: 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit image button
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                tooltip: loc.edit,
                onPressed: widget.onAddImage,
              ),
            ),
            const SizedBox(width: 8),
            // Remove image button
            if (widget.onRemoveImage != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  tooltip: loc.remove,
                  onPressed: widget.onRemoveImage,
                ),
              ),
          ],
        ),
      );
    } else {
      // Show add image button when no image exists
      return Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            tooltip: loc.addFlashcard,
            onPressed: widget.onAddImage,
          ),
        ),
      );
    }
  }
}