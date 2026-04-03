class Flashcard {
  final Map<String, String> translations;
  final String? imagePath;
  final bool hasLocalImage;
  final String? topicKey; // NEW: Store the original topic for audio lookup

  const Flashcard({
    required this.translations,
    this.imagePath,
    this.hasLocalImage = false,
    this.topicKey, // NEW
  });

  factory Flashcard.fromJson(Map<String, dynamic> json, {String? topicKey}) {
    return Flashcard(
      translations: Map<String, String>.from(json['translations'] ?? {}),
      imagePath: json['imagePath'],
      hasLocalImage: json['hasLocalImage'] ?? false,
      topicKey: json['topicKey'] ?? topicKey, // Use provided topicKey if not in JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translations': translations,
      'imagePath': imagePath,
      'hasLocalImage': hasLocalImage,
      'topicKey': topicKey,
    };
  }

  /// Get the translation for a specific language
  String getTranslation(String languageKey) {
    return translations[languageKey] ?? '';
  }

  /// Create a copy with updated image information
  Flashcard copyWithImage({String? imagePath, bool? hasLocalImage}) {
    return Flashcard(
      translations: Map<String, String>.from(translations),
      imagePath: imagePath ?? this.imagePath,
      hasLocalImage: hasLocalImage ?? this.hasLocalImage,
      topicKey: topicKey,
    );
  }

  /// Create a copy with updated translations
  Flashcard copyWithTranslations(Map<String, String> newTranslations) {
    return Flashcard(
      translations: newTranslations,
      imagePath: imagePath,
      hasLocalImage: hasLocalImage,
      topicKey: topicKey,
    );
  }

  /// Create a copy without image
  Flashcard copyWithoutImage() {
    return Flashcard(
      translations: Map<String, String>.from(translations),
      imagePath: null,
      hasLocalImage: false,
      topicKey: topicKey,
    );
  }

  /// Check if the card has translations for both languages
  bool hasTranslation(String languageKey) {
    return translations.containsKey(languageKey) &&
        translations[languageKey]!.isNotEmpty;
  }

  /// Get all available language keys
  List<String> get availableLanguages {
    return translations.keys
        .where((key) => translations[key]!.isNotEmpty)
        .toList();
  }

  /// Get a unique identifier for this card
  String get id {
    return translations['id'] ?? translations.values.first;
  }

  /// Maps a language code (e.g. 'es') to the full key used in the translations map (e.g. 'spanish')
  static String _languageCodeToKey(String code) {
    switch (code) {
      case 'es': return 'spanish';
      case 'hu': return 'hungarian';
      case 'en': return 'english';
      case 'pt': return 'portuguese';
      default: return code;
    }
  }

  /// Generates the audio file path for this flashcard
  /// Uses the card's original topic (stored in topicKey) for audio lookup
  /// Falls back to the provided topicKey parameter if card doesn't have one
  /// Returns null if the audio file doesn't exist or if required data is missing
  ///
  /// Parameters:
  /// - fallbackTopicKey: Optional topic key to use if card doesn't have one stored
  /// - language: The language code for the audio (e.g., 'es', 'hu'). Defaults to 'es' for Spanish
  ///
  /// Format: assets/audio/{topic}_{sanitized_word_in_target_language}_{language}.mp3
  /// Example: assets/audio/body_cabeza_es.mp3
  String? getAudioPath([String? fallbackTopicKey, String language = 'es']) {
    // Look up the word using the full language name key (e.g. 'spanish', not 'es')
    final languageKey = _languageCodeToKey(language);
    final word = translations[languageKey];

    // Return null if no translation exists for the target language
    if (word == null || word.isEmpty) {
      return null;
    }

    // Use card's topicKey if available, otherwise use fallback
    final topic = topicKey ?? fallbackTopicKey;

    // Return null if no topic is available
    if (topic == null || topic.isEmpty) {
      return null;
    }

    // Don't try to get audio for level-based topics
    if (topic.startsWith('level_') || topic == 'forgotten') {
      return null;
    }

    // Sanitize the word to match audio filename format
    final sanitizedWord = _sanitizeForAudioFilename(word);

    // Construct the full audio path with language code
    return 'assets/audio/${topic}_${sanitizedWord}_$language.mp3';
  }

  /// Sanitizes a word to match the audio filename convention
  ///
  /// Rules:
  /// 1. Convert to lowercase
  /// 2. Replace spaces, slashes, and parentheses with underscores
  /// 3. Remove other non-alphanumeric characters (except underscores and hyphens)
  ///
  /// Examples:
  /// - "good" -> "good"
  /// - "big/large" -> "big_large"
  /// - "old (new)" -> "old_new"
  /// - "short (vs long)" -> "short_vs_long"
  static String _sanitizeForAudioFilename(String word) {
    // 1. Convert to lowercase
    String sanitized = word.toLowerCase();

    // 2. Replace spaces, slashes, and parentheses with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[/\s()]+'), '_');

    // 3. Remove any other non-alphanumeric characters (except underscores and hyphens)
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '');

    // 4. Remove leading/trailing underscores
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');

    return sanitized;
  }

  /// Generates the audio filename for a flashcard
  ///
  /// Parameters:
  /// - topic: The topic key (e.g., 'adjectives', 'verbs')
  /// - word: The word/phrase in the target language
  /// - language: The language code (e.g., 'es' for Spanish, 'hu' for Hungarian)
  ///
  /// Returns: Filename in format: {topic}_{sanitized_word}_{language}.mp3
  /// Example: "body_cabeza_es.mp3"
  static String getAudioFilename(String topic, String word, String language) {
    final sanitized = _sanitizeForAudioFilename(word);
    return '${topic}_${sanitized}_$language.mp3';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Flashcard) return false;

    // Compare based on translations content, not image path or topic
    if (translations.length != other.translations.length) return false;

    for (final entry in translations.entries) {
      if (other.translations[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    // Hash based on translations content only
    int hash = 0;
    final sortedEntries = translations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedEntries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }

    return hash;
  }

  @override
  String toString() {
    return 'Flashcard(translations: $translations, imagePath: $imagePath, hasLocalImage: $hasLocalImage, topicKey: $topicKey)';
  }
}