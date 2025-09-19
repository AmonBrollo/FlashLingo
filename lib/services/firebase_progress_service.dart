import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';

class FirebaseProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's progress collection reference
  static CollectionReference? _getProgressCollection() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    return _firestore.collection('users').doc(user.uid).collection('progress');
  }

  /// Generate a unique key for a flashcard (consistent with RepetitionService)
  static String _generateCardKey(Flashcard card) {
    // Use card ID if available, otherwise fallback to first translation.
    // This matches the logic in RepetitionService
    return card.translations['id'] ?? card.translations.values.first;
  }

  /// Save flashcard progress to Firebase and local storage
  static Future<void> saveProgress(
    Flashcard card,
    FlashcardProgress progress,
  ) async {
    final cardKey = _generateCardKey(card);

    // Always save to local storage first
    await _saveProgressLocally(cardKey, progress);

    // Save to Firebase if user is authenticated
    final progressCollection = _getProgressCollection();
    if (progressCollection != null) {
      try {
        await progressCollection.doc(cardKey).set({
          'box': progress.box,
          'nextReview': Timestamp.fromDate(progress.nextReview),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving progress to Firebase: $e');
        // Continue using local storage if Firebase fails
      }
    }
  }

  /// Load flashcard progress from Firebase, fallback to local storage
  static Future<FlashcardProgress> loadProgress(Flashcard card) async {
    final cardKey = _generateCardKey(card);
    final progressCollection = _getProgressCollection();

    if (progressCollection != null) {
      try {
        final doc = await progressCollection.doc(cardKey).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final progress = FlashcardProgress(
            box: data['box'] ?? 1,
            nextReview: (data['nextReview'] as Timestamp?)?.toDate(),
          );

          // Also save to local storage for offline access
          await _saveProgressLocally(cardKey, progress);
          return progress;
        }
      } catch (e) {
        print('Error loading progress from Firebase: $e');
        // Fall through to local storage
      }
    }

    // Fallback to local storage
    return await _loadProgressLocally(cardKey);
  }

  /// Load all progress data from Firebase and sync to local storage
  static Future<Map<String, FlashcardProgress>> loadAllProgress() async {
    final Map<String, FlashcardProgress> allProgress = {};
    final progressCollection = _getProgressCollection();

    if (progressCollection != null) {
      try {
        final snapshot = await progressCollection.get();
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final progress = FlashcardProgress(
            box: data['box'] ?? 1,
            nextReview: (data['nextReview'] as Timestamp?)?.toDate(),
          );

          allProgress[doc.id] = progress;
          // Also save to local storage
          await _saveProgressLocally(doc.id, progress);
        }
        return allProgress;
      } catch (e) {
        print('Error loading all progress from Firebase: $e');
      }
    }

    // Fallback to local storage
    return await _loadAllProgressLocally();
  }

  /// Delete progress for a specific flashcard
  static Future<void> deleteProgress(Flashcard card) async {
    final cardKey = _generateCardKey(card);

    // Delete from local storage
    await _deleteProgressLocally(cardKey);

    // Delete from Firebase if user is authenticated
    final progressCollection = _getProgressCollection();
    if (progressCollection != null) {
      try {
        await progressCollection.doc(cardKey).delete();
      } catch (e) {
        print('Error deleting progress from Firebase: $e');
      }
    }
  }

  /// Clear all progress data
  static Future<void> clearAllProgress() async {
    // Clear local storage
    await _clearAllProgressLocally();

    // Clear Firebase if user is authenticated
    final progressCollection = _getProgressCollection();
    if (progressCollection != null) {
      try {
        final snapshot = await progressCollection.get();
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        print('Error clearing all progress from Firebase: $e');
      }
    }
  }

  /// Sync local progress to Firebase after login
  static Future<void> syncLocalToFirebase() async {
    final progressCollection = _getProgressCollection();
    if (progressCollection == null) return;

    try {
      final localProgress = await _loadAllProgressLocally();
      final batch = _firestore.batch();

      for (final entry in localProgress.entries) {
        final docRef = progressCollection.doc(entry.key);
        batch.set(docRef, {
          'box': entry.value.box,
          'nextReview': Timestamp.fromDate(entry.value.nextReview),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing local progress to Firebase: $e');
    }
  }

  // Local storage helper methods
  static Future<void> _saveProgressLocally(
    String cardKey,
    FlashcardProgress progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = {
      'box': progress.box,
      'nextReview': progress.nextReview.millisecondsSinceEpoch,
    };
    await prefs.setString('progress_$cardKey', json.encode(progressData));
  }

  static Future<FlashcardProgress> _loadProgressLocally(String cardKey) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('progress_$cardKey');

    if (progressJson != null) {
      final progressData = json.decode(progressJson);
      return FlashcardProgress(
        box: progressData['box'] ?? 1,
        nextReview: DateTime.fromMillisecondsSinceEpoch(
          progressData['nextReview'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    return FlashcardProgress();
  }

  static Future<Map<String, FlashcardProgress>>
  _loadAllProgressLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, FlashcardProgress> allProgress = {};

    for (final key in prefs.getKeys()) {
      if (key.startsWith('progress_')) {
        final cardKey = key.substring('progress_'.length);
        final progressJson = prefs.getString(key);

        if (progressJson != null) {
          final progressData = json.decode(progressJson);
          allProgress[cardKey] = FlashcardProgress(
            box: progressData['box'] ?? 1,
            nextReview: DateTime.fromMillisecondsSinceEpoch(
              progressData['nextReview'] ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
    }

    return allProgress;
  }

  static Future<void> _deleteProgressLocally(String cardKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('progress_$cardKey');
  }

  static Future<void> _clearAllProgressLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where((key) => key.startsWith('progress_'))
        .toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
