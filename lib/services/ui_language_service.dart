import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// Service to manage the UI language (not the learning language)
/// This determines which language the app interface is displayed in
class UiLanguageService {
  static const String _uiLanguageKey = 'ui_language';
  static String? _cachedLanguage;

  /// Get the current UI language code
  /// Returns 'pt' for Portuguese or 'en' for English
  static Future<String> getUiLanguage() async {
    if (_cachedLanguage != null) {
      return _cachedLanguage!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_uiLanguageKey);

      if (savedLanguage != null) {
        _cachedLanguage = savedLanguage;
        return savedLanguage;
      }

      // If no saved language, detect from system
      final systemLanguage = await _detectSystemLanguage();
      _cachedLanguage = systemLanguage;
      return systemLanguage;
    } catch (e) {
      print('Error getting UI language: $e');
      return 'en'; // Default to English on error
    }
  }

  /// Save the UI language preference
  static Future<void> setUiLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_uiLanguageKey, languageCode);
      _cachedLanguage = languageCode;
    } catch (e) {
      print('Error saving UI language: $e');
    }
  }

  /// Detect system language and return appropriate code
  static Future<String> _detectSystemLanguage() async {
    try {
      final String systemLocale = Platform.localeName;
      
      // Check if system is set to Portuguese (pt_BR, pt_PT, etc.)
      if (systemLocale.startsWith('pt')) {
        return 'pt';
      }
      
      // Default to English for all other cases
      return 'en';
    } catch (e) {
      print('Error detecting system language: $e');
      return 'en';
    }
  }

  /// Clear the cached language (useful for testing)
  static void clearCache() {
    _cachedLanguage = null;
  }

  /// Check if Portuguese is the UI language
  static Future<bool> isPortuguese() async {
    final lang = await getUiLanguage();
    return lang == 'pt';
  }

  /// Check if English is the UI language
  static Future<bool> isEnglish() async {
    final lang = await getUiLanguage();
    return lang == 'en';
  }
}