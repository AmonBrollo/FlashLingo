import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/flashcard.dart';
import '../models/flashcard_progress.dart';

class FirebaseProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Single key for all progress data (FAST!)
  static const String _allProgressKey = 'all_progress_v3'; // Bumped version for language support
  static const String _migrationKey = 'progress_migrated_v3';
  
  // In-memory cache for ultra-fast access
  static Map<String, FlashcardProgress>? _memoryCache;

  /// Get the current user's progress collection reference
  static CollectionReference? _getProgressCollection() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    return _firestore.collection('users').doc(user.uid).collection('progress');
  }

  /// Generate a unique key for a flashcard WITH language context
  static String _generateCardKey(
    Flashcard card,
    String baseLanguage,
    String targetLanguage,
  ) {
    final cardId = card.translations['id'] ?? card.translations.values.first;
    return '${baseLanguage}_${targetLanguage}_$cardId';
  }

  /// Save flashcard progress to Firebase and local storage
  static Future<void> saveProgress(
    Flashcard card,
    FlashcardProgress progress,
    String baseLanguage,
    String targetLanguage,
  ) async {
    final cardKey = _generateCardKey(card, baseLanguage, targetLanguage);

    // Update memory cache (instant!)
    _memoryCache ??= {};
    _memoryCache![cardKey] = progress;

    // Save to local storage immediately (non-blocking)
    _saveProgressToLocal(cardKey, progress);

    // Save to Firebase in background (completely non-blocking)
    _saveToFirebaseBackground(cardKey, progress);
  }

  /// Save to Firebase in background without blocking
  static void _saveToFirebaseBackground(String cardKey, FlashcardProgress progress) {
    Future.microtask(() async {
      final progressCollection = _getProgressCollection();
      if (progressCollection == null) return;

      try {
        await progressCollection
            .doc(cardKey)
            .set({
              'box': progress.box,
              'nextReview': Timestamp.fromDate(progress.nextReview),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        // Silent fail - local storage is primary
        print('Firebase save failed (expected if offline): $e');
      }
    });
  }

  /// Load flashcard progress from cache/local/firebase
  static Future<FlashcardProgress> loadProgress(
    Flashcard card,
    String baseLanguage,
    String targetLanguage,
  ) async {
    final cardKey = _generateCardKey(card, baseLanguage, targetLanguage);
    
    // Check memory cache first (instant!)
    if (_memoryCache != null && _memoryCache!.containsKey(cardKey)) {
      return _memoryCache![cardKey]!;
    }
    
    // Load all progress if not in cache
    final allProgress = await loadAllProgress();
    return allProgress[cardKey] ?? FlashcardProgress();
  }

  /// Load all progress data - OPTIMIZED VERSION
  static Future<Map<String, FlashcardProgress>> loadAllProgress() async {
    // Return memory cache if available (instant!)
    if (_memoryCache != null) {
      print('Using memory cache (${_memoryCache!.length} cards)');
      return Map.from(_memoryCache!);
    }

    final Map<String, FlashcardProgress> allProgress = {};

    // Check if we need to clear old format data
    await _clearOldProgressIfNeeded();

    // Load from local storage first (FAST - single key read)
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_allProgressKey);
      
      if (progressJson != null) {
        final Map<String, dynamic> progressMap = json.decode(progressJson);
        
        for (final entry in progressMap.entries) {
          try {
            allProgress[entry.key] = FlashcardProgress.fromJson(
              entry.value as Map<String, dynamic>,
            );
          } catch (e) {
            print('Error parsing progress for ${entry.key}: $e');
          }
        }
        
        print('Loaded ${allProgress.length} cards from local storage');
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }

    final progressCollection = _getProgressCollection();

    // If no authentication or anonymous, return local only
    if (progressCollection == null) {
      _memoryCache = allProgress;
      return allProgress;
    }

    // Load from Firebase (only if online and authenticated)
    try {
      final snapshot = await progressCollection
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isNotEmpty) {
        // Process all documents
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final progress = FlashcardProgress(
            box: data['box'] ?? 1,
            nextReview: (data['nextReview'] as Timestamp?)?.toDate(),
          );
          allProgress[doc.id] = progress;
        }

        // Save to local storage for offline access
        _saveAllProgressToLocal(allProgress);
        
        print('Loaded ${allProgress.length} cards from Firebase');
      }
    } catch (e) {
      print('Error loading from Firebase (using local): $e');
      // Continue with local progress
    }

    // Cache in memory
    _memoryCache = allProgress;
    return allProgress;
  }

  /// Delete progress for a specific flashcard
  static Future<void> deleteProgress(
    Flashcard card,
    String baseLanguage,
    String targetLanguage,
  ) async {
    final cardKey = _generateCardKey(card, baseLanguage, targetLanguage);

    // Remove from memory cache
    _memoryCache?.remove(cardKey);

    // Update local storage
    if (_memoryCache != null) {
      await _saveAllProgressToLocal(_memoryCache!);
    }

    // Delete from Firebase if user is authenticated
    final progressCollection = _getProgressCollection();
    if (progressCollection != null) {
      try {
        await progressCollection
            .doc(cardKey)
            .delete()
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        print('Error deleting progress from Firebase: $e');
      }
    }
  }

  /// Clear all progress data
  static Future<void> clearAllProgress() async {
    // Clear memory cache
    _memoryCache = null;

    // Clear local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_allProgressKey);
      await prefs.remove('all_progress_v2'); // Clear old version
      await prefs.remove(_migrationKey);
      
      // Also clear old format keys
      final keysToRemove = prefs
          .getKeys()
          .where((key) => key.startsWith('progress_'))
          .toList();
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing local storage: $e');
    }

    // Clear Firebase if user is authenticated
    final progressCollection = _getProgressCollection();
    if (progressCollection != null) {
      try {
        final snapshot = await progressCollection.get().timeout(
          const Duration(seconds: 5),
        );

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit().timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Error clearing Firebase: $e');
      }
    }
  }

  /// Sync local progress to Firebase after login
  static Future<void> syncLocalToFirebase() async {
    final progressCollection = _getProgressCollection();
    if (progressCollection == null) return;

    try {
      // Load from local storage
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_allProgressKey);
      
      if (progressJson == null) return;

      final Map<String, dynamic> progressMap = json.decode(progressJson);
      if (progressMap.isEmpty) return;

      final batch = _firestore.batch();
      int count = 0;

      for (final entry in progressMap.entries) {
        final docRef = progressCollection.doc(entry.key);
        final progressData = entry.value as Map<String, dynamic>;
        
        batch.set(docRef, {
          'box': progressData['box'],
          'nextReview': Timestamp.fromMillisecondsSinceEpoch(
            progressData['nextReview'],
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        count++;
        // Firestore batch limit is 500 operations
        if (count >= 500) {
          await batch.commit().timeout(const Duration(seconds: 10));
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit().timeout(const Duration(seconds: 10));
      }
      
      print('Synced $count cards to Firebase');
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }

  // ==================== OPTIMIZED LOCAL STORAGE ====================

  /// Save single progress to local storage (non-blocking)
  static void _saveProgressToLocal(String cardKey, FlashcardProgress progress) {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final progressJson = prefs.getString(_allProgressKey);
        
        Map<String, dynamic> allProgress = {};
        if (progressJson != null) {
          allProgress = json.decode(progressJson) as Map<String, dynamic>;
        }
        
        allProgress[cardKey] = progress.toJson();
        
        await prefs.setString(_allProgressKey, json.encode(allProgress));
      } catch (e) {
        print('Error saving to local storage: $e');
      }
    });
  }

  /// Save all progress to local storage (FAST - single write)
  static Future<void> _saveAllProgressToLocal(
    Map<String, FlashcardProgress> progressMap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final Map<String, dynamic> jsonMap = {};
      for (final entry in progressMap.entries) {
        jsonMap[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString(_allProgressKey, json.encode(jsonMap));
      print('Saved ${progressMap.length} cards to local storage');
    } catch (e) {
      print('Error saving all progress locally: $e');
    }
  }

  /// Clear old progress format on first launch with new system
  static Future<void> _clearOldProgressIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we've already migrated
      if (prefs.getBool(_migrationKey) == true) {
        return; // Already cleared
      }
      
      print('Clearing old progress format (language-agnostic)...');
      
      // Remove old version key
      await prefs.remove('all_progress_v2');
      
      // Remove old individual keys
      final oldKeys = prefs
          .getKeys()
          .where((key) => key.startsWith('progress_'))
          .toList();
      
      for (final key in oldKeys) {
        await prefs.remove(key);
      }
      
      // Mark as migrated
      await prefs.setBool(_migrationKey, true);
      
      print('Old progress cleared. Users start fresh with language-specific progress.');
    } catch (e) {
      print('Error clearing old progress: $e');
    }
  }

  /// Clear memory cache (useful for logout)
  static void clearMemoryCache() {
    _memoryCache = null;
  }

  /// Force reload from disk (bypass memory cache)
  static Future<Map<String, FlashcardProgress>> forceReload() async {
    _memoryCache = null;
    return await loadAllProgress();
  }
}