class FlashcardProgress {
  int box;
  DateTime nextReview;

  FlashcardProgress({this.box = 0, DateTime? nextReview})
    : nextReview = nextReview ?? DateTime.now();

  /// Whether this card has been studied at least once.
  bool get hasStarted => box > 0 || box == -1;

  /// Whether this card is in the trouble cards deck
  bool get isTroubleCard => box == -1;

  /// Whether this card is due for review (including overdue cards).
  /// Includes a 2-hour grace period to help users build consistent daily habits.
  bool isDue() {
    // Cards in box 0 (new/unseen) are always "due" for first study
    if (box == 0) return true;
    
    // Cards in box -1 (trouble cards) are always available for review
    if (box == -1) return true;
    
    // For cards in boxes 1-5, check if we're within the grace period
    // Grace period: cards become available 2 hours before their scheduled time
    final now = DateTime.now();
    final gracePeriod = const Duration(hours: 2);
    final dueWithGrace = nextReview.subtract(gracePeriod);
    
    return now.isAfter(dueWithGrace) || now.isAtSameMomentAs(dueWithGrace);
  }

  /// Promote the card to the next Leitner box (swipe right - remembered)
  void promote() {
    // If never studied (box 0), go to box 1
    if (box == 0) {
      box = 1;
    } 
    // If in trouble cards (box -1), go to box 1 (fresh start)
    else if (box == -1) {
      box = 1;
    }
    // If in boxes 1-4, promote to next box
    else if (box < 5) {
      box++;
    }
    // If already at box 5, stay at 5 but update the next review date
    _updateNextReview();
  }

  /// Reset the card based on current box level
  void reset() {
    // If card is in box 1 and forgotten, send to trouble cards (box -1)
    if (box == 1) {
      box = -1;
      // Trouble cards are always available (no interval)
      nextReview = DateTime.now();
    } 
    // If card is in boxes 2-5 and forgotten, send back to box 1
    else if (box > 1) {
      box = 1;
      _updateNextReview();
    }
    // If in trouble cards and forgotten again, stay in trouble cards
    else if (box == -1) {
      nextReview = DateTime.now();
    }
    // If unseen (box 0) and somehow reset, stay at 0
    else {
      box = 0;
      nextReview = DateTime.now();
    }
  }

  /// Internal helper to schedule the next review date.
  void _updateNextReview() {
    // Common Leitner intervals:
    // Box -1 (trouble cards) → no interval, always available
    // Box 0 (unseen) → no interval, available immediately in topic decks
    // Box 1 → 1 day (forgotten cards or first-time remembered)
    // Box 2 → 3 days
    // Box 3 → 7 days
    // Box 4 → 14 days
    // Box 5 → 30 days (mastered)
    final intervals = {
      -1: const Duration(days: 0), // Trouble cards always available
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
    if (box == 0 || box == -1) return 0; // New cards and trouble cards are always available
    
    final now = DateTime.now();
    final difference = nextReview.difference(now);
    return difference.inDays;
  }

  /// Check if card is overdue
  bool isOverdue() {
    if (box == 0 || box == -1) return false; // New cards and trouble cards can't be overdue
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