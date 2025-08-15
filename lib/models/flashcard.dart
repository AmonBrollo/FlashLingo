class Flashcard {
  final Map<String, String> translations;
  final String? imagePath;

  Flashcard({required this.translations, this.imagePath});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      translations: Map<String, String>.from(json['translations']),
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'translations': translations, 'imagePath': imagePath};
  }

  String getTranslation(String languageCode) {
    final aliases = {'en': 'english', 'pt': 'portuguese', 'hu': 'hungarian'};

    final normalized =
        aliases[languageCode.toLowerCase()] ?? languageCode.toLowerCase();

    if (translations.containsKey(normalized)) {
      return translations[normalized]!;
    }

    (throw ArgumentError('Unsuported language: $languageCode'));
  }
}
