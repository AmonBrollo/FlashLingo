class Flashcard {
  final Map<String, String> translations;
  final String? imagePath;
  int boxLevel;
  DateTime nextReview;

  Flashcard({
    required this.translations,
    this.imagePath,
    this.boxLevel = 1,
    DateTime? nextReview,
  }) : nextReview = nextReview ?? DateTime.now();

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      translations: Map<String, String>.from(json['translations']),
      imagePath: json['imagePath'],
      boxLevel: json['boxLevel'] ?? 1,
      nextReview: json['nextReview'] != null
          ? DateTime.parse(json['nextReview'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translations': translations,
      'imagePath': imagePath,
      'boxLevel': boxLevel,
      'nextReview': nextReview.toIso8601String(),
    };
  }

  String getTranslation(String languageCode) {
    const aliases = {
      'en': 'english',
      'english': 'english',
      'pt': 'portuguese',
      'portuguese': 'portuguese',
      'hu': 'hungarian',
      'hungarian': 'hungarian',
    };

    final normalized =
        aliases[languageCode.toLowerCase()] ?? languageCode.toLowerCase();

    if (translations.containsKey(normalized)) {
      return translations[normalized]!;
    }

    if (translations.containsKey('english')) {
      return translations['english']!;
    }

    (throw ArgumentError('Unsuported language: $languageCode'));
  }
}
