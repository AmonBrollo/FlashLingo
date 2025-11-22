class FlashcardProgress {
  int box;
  DateTime nextReview;

  FlashcardProgress({this.box = 0, DateTime? nextReview})
    : nextReview = nextReview ?? DateTime.now();

  /// Whether this card has been studied at least once.
  bool get hasStarted => box > 0;

  /// Whether this card is due for review (including overdue cards).
  bool isDue() {
    // Cards in box 0 (new/unseen) are always "due" for first study
    if (box == 0) return true;
    
    // For cards in boxes 1-5, check if the review date has passed
    return DateTime.now().isAfter(nextReview) || 
           DateTime.now().isAtSameMomentAs(nextReview);
  }

  /// Promote the card to the next Leitner box (swipe right - remembered)
  void promote() {
    // If never studied (box 0), go to box 1
    if (box == 0) {
      box = 1;
    } else if (box < 5) {
      box++;
    }
    // If already at box 5, stay at 5 but update the next review date
    _updateNextReview();
  }

  /// Reset the card to box 1 (swipe left - forgotten)
  void reset() {
    box = 1;
    _updateNextReview();
  }

  /// Internal helper to schedule the next review date.
  void _updateNextReview() {
    // Common Leitner intervals:
    // Box 0 (unseen) → no interval, available immediately in topic decks
    // Box 1 → 1 day (forgotten cards or first-time remembered)
    // Box 2 → 3 days
    // Box 3 → 7 days
    // Box 4 → 14 days
    // Box 5 → 30 days (mastered)
    final intervals = {
      0: const Duration(days: 0),
      1: const Duration(days: 1),
      2: const Duration(days: 3),
      3: const Duration(days: 7),
      4: const Duration(days: 14),
      5: const Duration(days: 30),
    };

    nextReview = DateTime.now().add(intervals[box] ?? const Duration(days: 1));
  }

  /// Get days until next review (negative if overdue)
  int daysUntilReview() {
    if (box == 0) return 0; // New cards are always available
    
    final now = DateTime.now();
    final difference = nextReview.difference(now);
    return difference.inDays;
  }

  /// Check if card is overdue
  bool isOverdue() {
    if (box == 0) return false; // New cards can't be overdue
    return DateTime.now().isAfter(nextReview);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {'box': box, 'nextReview': nextReview.millisecondsSinceEpoch};
  }

  /// Create from JSON
  factory FlashcardProgress.fromJson(Map<String, dynamic> json) {
    return FlashcardProgress(
      box: json['box'] ?? 0,
      nextReview: json['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['nextReview'])
          : null,
    );
  }

  /// Create a copy of this progress
  FlashcardProgress copy() {
    return FlashcardProgress(box: box, nextReview: nextReview);
  }

  @override
  String toString() {
    return 'FlashcardProgress(box: $box, nextReview: $nextReview, isDue: ${isDue()})';
  }
}