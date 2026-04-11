import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_service.dart';

class FirebaseUserPreferences {
  static const _baseLanguageKey = 'base_language';
  static const _targetLanguageKey = 'target_language';
  static const _deckKey = 'deck_key';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's document reference.
  static DocumentReference? _getUserDocument() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  /// Save user preferences to local storage and Firebase, then signal a sync.
  static Future<void> savePreferences({
    required String baseLanguage,
    required String targetLanguage,
    required String deckKey,
  }) async {
    // Local storage first — fast and reliable.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseLanguageKey, baseLanguage);
    await prefs.setString(_targetLanguageKey, targetLanguage);
    await prefs.setString(_deckKey, deckKey);

    // Firebase in background — non-blocking.
    _saveToFirebaseBackground({
      _baseLanguageKey: baseLanguage,
      _targetLanguageKey: targetLanguage,
      _deckKey: deckKey,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Notify sync service that local state changed.
    SyncService().markDataChanged();
  }

  /// Write preferences to Firebase without blocking the caller.
  static void _saveToFirebaseBackground(Map<String, dynamic> preferences) {
    Future.microtask(() async {
      final userDoc = _getUserDocument();
      if (userDoc == null) return;

      try {
        await userDoc
            .set({'preferences': preferences}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        print('Firebase preference save failed (expected if offline): $e');
      }
    });
  }

  /// Load preferences from Firebase, falling back to local storage.
  static Future<Map<String, String?>> loadPreferences() async {
    final userDoc = _getUserDocument();

    if (userDoc != null) {
      try {
        final doc = await userDoc.get().timeout(const Duration(seconds: 8));

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final preferences = data?['preferences'] as Map<String, dynamic>?;

          if (preferences != null) {
            final baseLanguage = preferences[_baseLanguageKey] as String?;
            final targetLanguage = preferences[_targetLanguageKey] as String?;
            final deckKey = preferences[_deckKey] as String?;

            // Mirror to local storage for offline access.
            final prefs = await SharedPreferences.getInstance();
            if (baseLanguage != null) {
              await prefs.setString(_baseLanguageKey, baseLanguage);
            }
            if (targetLanguage != null) {
              await prefs.setString(_targetLanguageKey, targetLanguage);
            }
            if (deckKey != null) {
              await prefs.setString(_deckKey, deckKey);
            }

            return {
              'baseLanguage': baseLanguage,
              'targetLanguage': targetLanguage,
              'deckKey': deckKey,
            };
          }
        }
      } catch (e) {
        print('Error loading preferences from Firebase: $e');
        // Fall through to local storage.
      }
    }

    return loadPreferencesLocal();
  }

  /// Load preferences from local storage only (no Firebase).
  static Future<Map<String, String?>> loadPreferencesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'baseLanguage': prefs.getString(_baseLanguageKey),
      'targetLanguage': prefs.getString(_targetLanguageKey),
      'deckKey': prefs.getString(_deckKey),
    };
  }

  /// Get a single preference by its storage key.
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

  /// Returns true when all three setup keys are present.
  static Future<bool> isSetupComplete() async {
    final preferences = await loadPreferences();
    return preferences['baseLanguage'] != null &&
        preferences['targetLanguage'] != null &&
        preferences['deckKey'] != null;
  }

  /// Remove all stored preferences from local storage and Firebase.
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final userDoc = _getUserDocument();
    if (userDoc != null) {
      try {
        await userDoc
            .update({'preferences': FieldValue.delete()})
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Error clearing preferences from Firebase: $e');
      }
    }
  }

  /// Returns true when a non-anonymous user is signed in.
  static bool isLoggedIn() {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Push whatever is in local storage up to Firebase.
  ///
  /// Intentionally does NOT call [savePreferences] — that would trigger
  /// [SyncService.markDataChanged] and schedule another sync, creating
  /// an indirect recursive loop:
  ///
  ///   syncNow → syncLocalToFirebase → savePreferences → markDataChanged
  ///           → syncNow → syncLocalToFirebase → …
  ///
  /// Instead we write directly to Firebase and leave sync scheduling
  /// entirely to the [SyncService] that called us.
  static Future<void> syncLocalToFirebase() async {
    final userDoc = _getUserDocument();
    if (userDoc == null) return;

    final prefs = await SharedPreferences.getInstance();
    final baseLanguage = prefs.getString(_baseLanguageKey);
    final targetLanguage = prefs.getString(_targetLanguageKey);
    final deckKey = prefs.getString(_deckKey);

    if (baseLanguage == null || targetLanguage == null || deckKey == null) {
      return; // Nothing to push.
    }

    try {
      await userDoc.set(
        {
          'preferences': {
            _baseLanguageKey: baseLanguage,
            _targetLanguageKey: targetLanguage,
            _deckKey: deckKey,
            'updated_at': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Firebase preference sync failed (expected if offline): $e');
      rethrow; // Let SyncService handle retry logic.
    }
  }
}