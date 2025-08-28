import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPreferences {
  static const _baseLanguageKey = 'base_language';
  static const _targetLanguageKey = 'target_language';
  static const _deckKey = 'deck_key';

  /// Save the current user preferences
  static Future<void> savePreferences({
    required String baseLanguage,
    required String targetLanguage,
    required String deckKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseLanguageKey, baseLanguage);
    await prefs.setString(_targetLanguageKey, targetLanguage);
    await prefs.setString(_deckKey, deckKey);
  }

  /// Load all preferences at once
  static Future<Map<String, String?>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'baseLanguage': prefs.getString(_baseLanguageKey),
      'targetLanguage': prefs.getString(_targetLanguageKey),
      'deckKey': prefs.getString(_deckKey),
    };
  }

  /// Get a single preference
  static Future<String?> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Check if basic setup is complete (all required preferences exist)
  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_baseLanguageKey) &&
        prefs.containsKey(_targetLanguageKey) &&
        prefs.containsKey(_deckKey);
  }

  /// Clear all stored preferences (logout/reset)
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Check if a user is currently logged in
  static bool isLoggedIn() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
}
