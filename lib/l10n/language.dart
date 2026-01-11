/// Represents a language in the app
class Language {
  final String code; // ISO 639-1 code (pt, en, hu, es)
  final String name; // Display name in the language itself
  final String englishName; // English name
  final String flag; // Emoji flag
  final String legacyCode; // For backward compatibility (portuguese, english, hungarian, spanish)

  const Language({
    required this.code,
    required this.name,
    required this.englishName,
    required this.flag,
    required this.legacyCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($code)';
}

/// Available languages in the app
class AppLanguages {
  // Supported languages
  static const Language portuguese = Language(
    code: 'pt',
    name: 'Português',
    englishName: 'Portuguese',
    flag: '🇧🇷',
    legacyCode: 'portuguese',
  );

  static const Language english = Language(
    code: 'en',
    name: 'English',
    englishName: 'English',
    flag: '🇬🇧',
    legacyCode: 'english',
  );

  static const Language hungarian = Language(
    code: 'hu',
    name: 'Magyar',
    englishName: 'Hungarian',
    flag: '🇭🇺',
    legacyCode: 'hungarian',
  );

  static const Language spanish = Language(
    code: 'es',
    name: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
    legacyCode: 'spanish',
  );

  // List of all supported base languages (UI languages)
  static const List<Language> baseLanguages = [
    portuguese,
    english,
  ];

  // List of all supported target languages (learning languages)
  static const List<Language> targetLanguages = [
    hungarian,
    spanish,
    english,
    portuguese,
  ];

  // All languages
  static const List<Language> allLanguages = [
    portuguese,
    english,
    hungarian,
    spanish,
  ];

  /// Get language by code (supports both ISO and legacy codes)
  static Language? getLanguage(String code) {
    final normalizedCode = code.toLowerCase();
    
    // Try ISO code first
    for (final lang in allLanguages) {
      if (lang.code == normalizedCode) return lang;
    }
    
    // Try legacy code for backward compatibility
    for (final lang in allLanguages) {
      if (lang.legacyCode == normalizedCode) return lang;
    }
    
    return null;
  }

  /// Get language by code or return default (English)
  static Language getLanguageOrDefault(String? code) {
    if (code == null) return english;
    return getLanguage(code) ?? english;
  }

  /// Check if a language is supported as base language
  static bool isSupportedBaseLanguage(String code) {
    final lang = getLanguage(code);
    if (lang == null) return false;
    return baseLanguages.contains(lang);
  }

  /// Check if a language is supported as target language
  static bool isSupportedTargetLanguage(String code) {
    final lang = getLanguage(code);
    if (lang == null) return false;
    return targetLanguages.contains(lang);
  }

  /// Get target languages for a specific base language
  static List<Language> getAvailableTargetLanguages(String baseLanguageCode) {
    final baseLang = getLanguage(baseLanguageCode);
    if (baseLang == null) return targetLanguages;
    
    // Return all target languages except the base language itself
    return targetLanguages.where((lang) => lang != baseLang).toList();
  }

  /// Normalize language code (convert legacy to ISO)
  static String normalizeCode(String code) {
    final lang = getLanguage(code);
    return lang?.code ?? code;
  }
}