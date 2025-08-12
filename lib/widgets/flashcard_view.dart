import 'dart:io';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class FlashcardView extends StatefulWidget {
  final Flashcard flashcard;
  final bool isFlipped;
  final String baseLanguage;
  final VoidCallback onFlip;
  final VoidCallback onAddImage;
  final VoidCallback onRemembered;
  final VoidCallback onForgotten;

  const FlashcardView({
    super.key,
    required this.flashcard,
    required this.isFlipped,
    required this.baseLanguage,
    required this.onFlip,
    required this.onAddImage,
    required this.onRemembered,
    required this.onForgotten,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  double _dragDx = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragDx += details.delta.dx;
        });
      },
      onPanEnd: (details) {
        if (_dragDx > 100) {
          widget.onRemembered();
        } else if (_dragDx < -100) {
          widget.onForgotten();
        }
        setState(() {
          _dragDx = 0.0;
        });
      },
      onTap: widget.onFlip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30,
            child: Opacity(
              opacity: _dragDx > 0 ? (_dragDx / 150).clamp(0, 1) : 0,
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
              opacity: _dragDx < 0 ? (-_dragDx / 150).clamp(0, 1) : 0,
              child: const Icon(Icons.cancel, color: Colors.red, size: 80),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
              child: Stack(
                children: [
                  Center(
                    child: widget.isFlipped
                        ? Text(
                            widget.flashcard.hungarian,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : (widget.flashcard.imagePath != null
                              ? Image.file(
                                  File(widget.flashcard.imagePath!),
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  widget.baseLanguage == "portuguese"
                                      ? widget.flashcard.portuguese
                                      : widget.flashcard.english,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                  ),
                  if (widget.flashcard.imagePath == null)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.baseLanguage == "portuguese"
                            ? "Nenhuma imagem ainda"
                            : "No image yet",
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
                      tooltip: widget.baseLanguage == 'portuguese'
                          ? 'Adicionar imagem'
                          : 'Add image',
                      onPressed: widget.onAddImage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
