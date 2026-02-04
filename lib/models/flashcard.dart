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
  
  /// Generates the audio file path for this flashcard
  /// Uses the card's original topic (stored in topicKey) for audio lookup
  /// Falls back to the provided topicKey parameter if card doesn't have one
  /// Returns null if the audio file doesn't exist or if required data is missing
  /// 
  /// Format: assets/audio/{topic}_{sanitized_english_word}.mp3
  /// Example: assets/audio/adjectives_good.mp3
  String? getAudioPath([String? fallbackTopicKey]) {
    final englishWord = translations['english'];
    
    // Return null if no English translation exists
    if (englishWord == null || englishWord.isEmpty) {
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
    
    // Sanitize the English word to match audio filename format
    final sanitizedWord = _sanitizeForAudioFilename(englishWord);
    
    // Construct the full audio path
    return 'assets/audio/${topic}_$sanitizedWord.mp3';
  }
  
  /// Sanitizes an English word to match the audio filename convention
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

  /// Legacy method - kept for backwards compatibility
  /// Use getAudioPath() instead for better null safety
  @Deprecated('Use getAudioPath() instead')
  static String getAudioFilename(String topic, String englishWord) {
    final sanitized = _sanitizeForAudioFilename(englishWord);
    return '${topic}_$sanitized';
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