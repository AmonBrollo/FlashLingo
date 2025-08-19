class Flashcard {
  final Map<String, String> translations;
  final String? imagePath;
  int level;

  Flashcard({required this.translations, this.imagePath, this.level = 1});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      translations: Map<String, String>.from(json['translations']),
      imagePath: json['imagePath'],
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translations': translations,
      'imagePath': imagePath,
      'level': level,
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
