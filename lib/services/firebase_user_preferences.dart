import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseUserPreferences {
  static const _baseLanguageKey = 'base_language';
  static const _targetLanguageKey = 'target_language';
  static const _deckKey = 'deck_key';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's document reference
  static DocumentReference? _getUserDocument() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    return _firestore.collection('users').doc(user.uid);
  }

  /// Save user preferences to Firebase and local storage
  static Future<void> savePreferences({
    required String baseLanguage,
    required String targetLanguage,
    required String deckKey,
  }) async {
    final preferences = {
      _baseLanguageKey: baseLanguage,
      _targetLanguageKey: targetLanguage,
      _deckKey: deckKey,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Always save to local storage first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseLanguageKey, baseLanguage);
    await prefs.setString(_targetLanguageKey, targetLanguage);
    await prefs.setString(_deckKey, deckKey);

    // Save to Firebase if user is authenticated and not anonymous
    final userDoc = _getUserDocument();
    if (userDoc != null) {
      try {
        await userDoc.set({
          'preferences': preferences,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving preferences to Firebase: $e');
        // Continue using local storage if Firebase fails
      }
    }
  }

  /// Load preferences from Firebase, fallback to local storage
  static Future<Map<String, String?>> loadPreferences() async {
    final userDoc = _getUserDocument();

    if (userDoc != null) {
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final preferences = data?['preferences'] as Map<String, dynamic>?;

          if (preferences != null) {
            // Also save to local storage for offline access
            final prefs = await SharedPreferences.getInstance();
            final baseLanguage = preferences[_baseLanguageKey] as String?;
            final targetLanguage = preferences[_targetLanguageKey] as String?;
            final deckKey = preferences[_deckKey] as String?;

            if (baseLanguage != null)
              await prefs.setString(_baseLanguageKey, baseLanguage);
            if (targetLanguage != null)
              await prefs.setString(_targetLanguageKey, targetLanguage);
            if (deckKey != null) await prefs.setString(_deckKey, deckKey);

            return {
              'baseLanguage': baseLanguage,
              'targetLanguage': targetLanguage,
              'deckKey': deckKey,
            };
          }
        }
      } catch (e) {
        print('Error loading preferences from Firebase: $e');
        // Fall through to local storage
      }
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return {
      'baseLanguage': prefs.getString(_baseLanguageKey),
      'targetLanguage': prefs.getString(_targetLanguageKey),
      'deckKey': prefs.getString(_deckKey),
    };
  }

  /// Get a single preference
  static Future<String?> getPreference(String key) async {
    final preferences = await loadPreferences();
    switch (key) {
      case _baseLanguageKey:
        return preferences['baseLanguage'];
      case _targetLanguageKey:
        return preferences['targetLanguage'];
      case _deckKey:
        return preferences['deckKey'];
      default:
        return null;
    }
  }

  /// Check if basic setup is complete
  static Future<bool> isSetupComplete() async {
    final preferences = await loadPreferences();
    return preferences['baseLanguage'] != null &&
        preferences['targetLanguage'] != null &&
        preferences['deckKey'] != null;
  }

  /// Clear all stored preferences
  static Future<void> clearPreferences() async {
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Clear Firebase if user is authenticated
    final userDoc = _getUserDocument();
    if (userDoc != null) {
      try {
        await userDoc.update({'preferences': FieldValue.delete()});
      } catch (e) {
        print('Error clearing preferences from Firebase: $e');
      }
    }
  }

  /// Check if a user is currently logged in and not anonymous
  static bool isLoggedIn() {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Sync local preferences to Firebase after login
  static Future<void> syncLocalToFirebase() async {
    final userDoc = _getUserDocument();
    if (userDoc == null) return;

    final prefs = await SharedPreferences.getInstance();
    final baseLanguage = prefs.getString(_baseLanguageKey);
    final targetLanguage = prefs.getString(_targetLanguageKey);
    final deckKey = prefs.getString(_deckKey);

    if (baseLanguage != null && targetLanguage != null && deckKey != null) {
      await savePreferences(
        baseLanguage: baseLanguage,
        targetLanguage: targetLanguage,
        deckKey: deckKey,
      );
    }
  }
}
