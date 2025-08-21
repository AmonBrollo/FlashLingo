import 'dart:io';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';
import '../utils/ui_strings.dart';

class FlashcardView extends StatelessWidget {
  final Flashcard flashcard;
  final FlashcardProgress progress;
  final bool isFlipped;
  final String baseLanguage;
  final String targetLanguage;
  final double dragDx;
  final VoidCallback onFlip;
  final VoidCallback onAddImage;
  final VoidCallback onRemembered;
  final VoidCallback onForgotten;

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
    required this.onRemembered,
    required this.onForgotten,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = MediaQuery.of(context).size.height * 0.5;

    final statusText = progress.hasStarted
        ? "Review - Level ${progress.box}"
        : "New";

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

                // main card content
                Center(
                  child: isFlipped
                      ? Text(
                          flashcard.getTranslation(targetLanguage),
                          textAlign: TextAlign.center,
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
                                flashcard.getTranslation(baseLanguage),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                ),

                if (!isFlipped && flashcard.imagePath == null)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Text(
                      UiStrings.noImageText(baseLanguage),
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
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    tooltip: UiStrings.addFlashcardButton(baseLanguage),
                    onPressed: onAddImage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
