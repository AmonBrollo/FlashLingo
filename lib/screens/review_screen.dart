import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/repetition_service.dart';
import '../services/ui_language_provider.dart';

class ReviewScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final String baseLanguage;
  final String targetLanguage;

  const ReviewScreen({
    super.key,
    required this.cards,
    required this.baseLanguage,
    required this.targetLanguage,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final RepetitionService _repetitionService = RepetitionService();
  bool _isLoading = true;
  Map<int, List<Flashcard>> _groupedCards = {};

  @override
  void initState() {
    super.initState();
    // Set language context for repetition service
    _repetitionService.setLanguageContext(widget.baseLanguage, widget.targetLanguage);
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      // Initialize repetition service with language context
      await _repetitionService.initialize(
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );

      // Preload progress for all cards
      await _repetitionService.preloadProgress(
        widget.cards,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );

      // Group cards by their current box level
      final grouped = _groupByLevel(widget.cards);

      if (mounted) {
        setState(() {
          _groupedCards = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading review data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<int, List<Flashcard>> _groupByLevel(List<Flashcard> cards) {
    final Map<int, List<Flashcard>> grouped = {};

    for (final card in cards) {
      final progress = _repetitionService.getProgress(
        card,
        baseLanguage: widget.baseLanguage,
        targetLanguage: widget.targetLanguage,
      );
      final box = progress.box;
      grouped.putIfAbsent(box, () => []).add(card);
    }

    return grouped;
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.red[600]!;
      case 2:
        return Colors.orange[600]!;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.blue[600]!;
      case 5:
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getNextReviewText(Flashcard card) {
    final loc = context.read<UiLanguageProvider>().loc;
    final progress = _repetitionService.getProgress(
      card,
      baseLanguage: widget.baseLanguage,
      targetLanguage: widget.targetLanguage,
    );
    final nextReview = progress.nextReview;
    final now = DateTime.now();
    final difference = nextReview.difference(now);

    if (difference.isNegative) {
      return loc.dueNow;
    } else if (difference.inDays > 0) {
      return loc.dueInDays(difference.inDays);
    } else if (difference.inHours > 0) {
      return loc.dueInHours(difference.inHours);
    } else {
      return loc.dueInMinutes(difference.inMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.reviewProgress),
          backgroundColor: Colors.brown,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
              const SizedBox(height: 16),
              Text(loc.loadingReviewData),
            ],
          ),
        ),
      );
    }

    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.reviewProgress),
          backgroundColor: Colors.brown,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                loc.noCardsToReviewYet,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                loc.studyFlashcardsToSeeHere,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final levels = _groupedCards.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reviewProgress),
        backgroundColor: Colors.brown,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.cards.length} ${loc.cardsLowercase}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final levelCards = _groupedCards[level]!;
            final levelColor = _getLevelColor(level);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: levelColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.levelDescription(level),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: levelColor,
                              ),
                            ),
                            Text(
                              loc.cardsTotal(levelCards.length),
                              style: TextStyle(
                                fontSize: 12,
                                color: levelColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cards grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 4,
                  ),
                  itemCount: levelCards.length,
                  itemBuilder: (context, i) {
                    final card = levelCards[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: levelColor.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Card content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    card.getTranslation(widget.baseLanguage),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    card.getTranslation(widget.targetLanguage),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Next review info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (card.hasLocalImage)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 12,
                                          color: Colors.blue[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          loc.image,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _getNextReviewText(card),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}