// flashcard.dart
import 'package:collection/collection.dart';

class Flashcard {
  final Map<String, String> translations;
  final String? imagePath;
  final bool hasLocalImage;

  const Flashcard({
    required this.translations,
    this.imagePath,
    this.hasLocalImage = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      translations: Map<String, String>.from(json['translations'] ?? {}),
      imagePath: json['imagePath'],
      hasLocalImage: json['hasLocalImage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translations': translations,
      'imagePath': imagePath,
      'hasLocalImage': hasLocalImage,
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
    );
  }

  /// Create a copy with updated translations
  Flashcard copyWithTranslations(Map<String, String> newTranslations) {
    return Flashcard(
      translations: newTranslations,
      imagePath: imagePath,
      hasLocalImage: hasLocalImage,
    );
  }

  /// Create a copy without image
  Flashcard copyWithoutImage() {
    return Flashcard(
      translations: Map<String, String>.from(translations),
      imagePath: null,
      hasLocalImage: false,
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
  
  /// Generates a standardized filename for the audio asset.
  /// Format: topic_englishword.mp3 (sanitized)
  static String getAudioFilename(String topic, String englishWord) {
    // 1. Convert to lowercase
    String sanitized = englishWord.toLowerCase();
    
    // 2. Replace slashes, spaces, and parentheses with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[/\s()]+'), '_');
    
    // 3. Remove any other non-alphanumeric characters (except underscores and hyphens)
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '');
    
    // 4. Combine topic and sanitized word
    return '${topic}_$sanitized';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Flashcard) return false;

    // Compare based on translations content, not image path
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
    return 'Flashcard(translations: $translations, imagePath: $imagePath, hasLocalImage: $hasLocalImage)';
  }
}