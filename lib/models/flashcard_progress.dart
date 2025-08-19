class FlashcardProgress {
  int box;
  DateTime nextReview;

  FlashcardProgress({this.box = 1, DateTime? nextReview})
    : nextReview = nextReview ?? DateTime.now();

  /// Whether this card has been studied at least once.
  bool get hasStarted => box > 1 || nextReview.isAfter(DateTime.now());

  /// Whether this card is due for review.
  bool isDue() => DateTime.now().isAfter(nextReview);

  /// Promote the card to the next Leitner box.
  void promote() {
    if (box < 5) box++;
    _updateNextReview();
  }

  void reset() {
    box = 1;
    _updateNextReview();
  }

  /// Internal helper to schedule the next review date.
  void _updateNextReview() {
    // Simple Leitner intervals (example):
    // Box 1 → 1 day, Box 2 → 2 days, Box 3 → 4 days, Box 4 → 7 days, Box 5 → 15 days
    final intervals = {
      1: const Duration(days: 1),
      2: const Duration(days: 2),
      3: const Duration(days: 4),
      4: const Duration(days: 7),
      5: const Duration(days: 15),
    };

    nextReview = DateTime.now().add(intervals[box]!);
  }
}
