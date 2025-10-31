import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_step.dart';
import 'error_handler_service.dart';

/// Service to manage tutorial state and progression
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _tutorialSkippedKey = 'tutorial_skipped';
  static const String _lastStepKey = 'tutorial_last_step';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's document reference
  static DocumentReference? _getUserDocument() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  /// Check if user has completed the tutorial
  static Future<bool> isTutorialCompleted() async {
    try {
      // Try Firebase first
      final userDoc = _getUserDocument();
      if (userDoc != null) {
        try {
          final doc = await userDoc.get().timeout(const Duration(seconds: 3));
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            final completed = data?['tutorial_completed'] as bool?;
            if (completed != null) {
              // Save to local for offline access
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_tutorialCompletedKey, completed);
              return completed;
            }
          }
        } catch (e) {
          // Firebase failed, fall through to local
          await ErrorHandlerService.logError(
            e,
            StackTrace.current,
            context: 'Tutorial Check Firebase',
            fatal: false,
          );
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tutorialCompletedKey) ?? false;
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Tutorial Check',
        fatal: false,
      );
      return false;
    }
  }

  /// Check if user has skipped the tutorial
  static Future<bool> isTutorialSkipped() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tutorialSkippedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark tutorial as completed
  static Future<void> completeTutorial() async {
    try {
      await ErrorHandlerService.logMessage('Tutorial completed');

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialCompletedKey, true);
      await prefs.setBool(_tutorialSkippedKey, false);
      await prefs.remove(_lastStepKey);

      // Save to Firebase
      final userDoc = _getUserDocument();
      if (userDoc != null) {
        try {
          await userDoc.set(
            {
              'tutorial_completed': true,
              'tutorial_completed_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Continue even if Firebase fails
          await ErrorHandlerService.logError(
            e,
            StackTrace.current,
            context: 'Tutorial Complete Firebase',
            fatal: false,
          );
        }
      }
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Complete Tutorial',
        fatal: false,
      );
    }
  }

  /// Mark tutorial as skipped
  static Future<void> skipTutorial() async {
    try {
      await ErrorHandlerService.logMessage('Tutorial skipped');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialSkippedKey, true);
      await prefs.setBool(_tutorialCompletedKey, true); // Also mark as completed
      await prefs.remove(_lastStepKey);

      // Save to Firebase
      final userDoc = _getUserDocument();
      if (userDoc != null) {
        try {
          await userDoc.set(
            {
              'tutorial_completed': true,
              'tutorial_skipped': true,
              'tutorial_skipped_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Continue even if Firebase fails
        }
      }
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Skip Tutorial',
        fatal: false,
      );
    }
  }

  /// Reset tutorial (for replay from profile)
  static Future<void> resetTutorial() async {
    try {
      await ErrorHandlerService.logMessage('Tutorial reset');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialCompletedKey, false);
      await prefs.setBool(_tutorialSkippedKey, false);
      await prefs.remove(_lastStepKey);

      // Don't update Firebase - keep record that they completed it once
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Reset Tutorial',
        fatal: false,
      );
    }
  }

  /// Save current step progress
  static Future<void> saveCurrentStep(int stepIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastStepKey, stepIndex);
    } catch (e) {
      // Non-critical, just log
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Save Tutorial Step',
        fatal: false,
      );
    }
  }

  /// Get last completed step (for resuming)
  static Future<int> getLastStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastStepKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if tutorial should be shown
  static Future<bool> shouldShowTutorial() async {
    final completed = await isTutorialCompleted();
    final skipped = await isTutorialSkipped();
    return !completed && !skipped;
  }

  /// Get tutorial steps for the user's language
  static List<TutorialStep> getTutorialSteps(String language) {
    return TutorialConfig.getSteps(language);
  }

  /// Get steps for a specific screen
  static List<TutorialStep> getStepsForScreen(
    String language,
    String screen,
  ) {
    final allSteps = getTutorialSteps(language);
    return allSteps.where((step) => step.screen == screen).toList();
  }

  /// Log tutorial analytics
  static Future<void> logTutorialEvent(String event, {int? stepIndex}) async {
    await ErrorHandlerService.logUserAction(
      'Tutorial: $event',
      params: stepIndex != null ? {'step': stepIndex} : null,
    );
  }
}