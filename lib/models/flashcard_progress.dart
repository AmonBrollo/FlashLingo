class FlashcardProgress {
  int boxLevel;
  DateTime nextReview;

  FlashcardProgress({this.boxLevel = 1, DateTime? nextReview})
    : nextReview = nextReview ?? DateTime.now();

  void promote() {
    if (boxLevel < 5) boxLevel++;
    nextReview = DateTime.now().add(_intervalForBox(boxLevel));
  }

  void reset() {
    boxLevel = 1;
    nextReview = DateTime.now().add(_intervalForBox(boxLevel));
  }

  bool isDue() {
    return nextReview.isBefore(DateTime.now());
  }

  static Duration _intervalForBox(int level) {
    switch (level) {
      case 1:
        return const Duration(hours: 5);
      case 2:
        return const Duration(days: 1);
      case 3:
        return const Duration(days: 3);
      case 4:
        return const Duration(days: 7);
      case 5:
        return const Duration(days: 30);
      default:
        return const Duration(days: 1);
    }
  }

  Map<String, dynamic> toJson() {
    return {'boxLevel': boxLevel, 'nextReview': nextReview.toIso8601String()};
  }

  factory FlashcardProgress.fromJson(Map<String, dynamic> json) {
    return FlashcardProgress(
      boxLevel: json['boxLevel'],
      nextReview: DateTime.parse(json['nextReview']),
    );
  }
}
