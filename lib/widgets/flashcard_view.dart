import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';
import '../services/ui_language_provider.dart';

class FlashcardView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = MediaQuery.of(context).size.height * 0.5;

    final statusText = progress.hasStarted
        ? loc.levelName(progress.box)
        : loc.newCard;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 30,
          child: Opacity(
            opacity: dragDx > 0 ? (dragDx / 150).clamp(0, 1).toDouble() : 0,
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
            opacity: dragDx < 0 ? (-dragDx / 150).clamp(0, 1).toDouble() : 0,
            child: const Icon(Icons.cancel, color: Colors.red, size: 80),
          ),
        ),

        Transform.translate(
          offset: Offset(dragDx, 0),
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
                      color: progress.hasStarted
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

                // Main card content
                Center(child: _buildCardContent(context)),

                // No image text (only shown when not flipped and no image)
                if (!isFlipped && !flashcard.hasLocalImage)
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
                if (!isFlipped) _buildImageControls(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(BuildContext context) {
    // Determine which translation to show
    final String cardText = isFlipped
        ? flashcard.getTranslation(targetLanguage)
        : flashcard.getTranslation(baseLanguage);

    if (!isFlipped && flashcard.hasLocalImage && flashcard.imagePath != null) {
      // Front side with image - no audio button here
      return _buildImageContent();
    } else if (isFlipped) {
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
                  onPressed: onPlayAudio,
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
                File(flashcard.imagePath!),
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
                  flashcard.getTranslation(baseLanguage),
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
    
    if (flashcard.hasLocalImage) {
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
                onPressed: onAddImage,
              ),
            ),
            const SizedBox(width: 8),
            // Remove image button
            if (onRemoveImage != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  tooltip: loc.remove,
                  onPressed: onRemoveImage,
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
            onPressed: onAddImage,
          ),
        ),
      );
    }
  }
}