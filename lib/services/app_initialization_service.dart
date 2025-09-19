import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'repetition_service.dart';

class AppInitializationService {
  static bool _initialized = false;

  /// Initialize the app services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase Auth listener
      FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);

      // If user is already logged in and not anonymous, sync data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await _syncDataToFirebase();
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing app services: $e');
      // Continue with app initialization even if Firebase fails
      _initialized = true;
    }
  }

  /// Handle authentication state changes
  static Future<void> _handleAuthStateChange(User? user) async {
    if (user != null && !user.isAnonymous) {
      // User logged in - sync local data to Firebase
      await _syncDataToFirebase();
    }
    // Note: We don't clear data on logout to maintain offline functionality
  }

  /// Sync local data to Firebase
  static Future<void> _syncDataToFirebase() async {
    try {
      // Sync user preferences
      await FirebaseUserPreferences.syncLocalToFirebase();

      // Sync progress data
      await FirebaseProgressService.syncLocalToFirebase();

      print('Successfully synced local data to Firebase');
    } catch (e) {
      print('Error syncing data to Firebase: $e');
    }
  }

  /// Get initialization status
  static bool get isInitialized => _initialized;

  /// Force re-initialization (useful for testing or error recovery)
  static Future<void> reinitialize() async {
    _initialized = false;
    await initialize();
  }

  /// Prepare user data after login
  static Future<void> prepareUserData() async {
    try {
      // Load all progress data into cache
      final repetitionService = RepetitionService();
      await repetitionService.initialize();

      print('User data prepared successfully');
    } catch (e) {
      print('Error preparing user data: $e');
    }
  }

  /// Clear all local data (useful for logout/reset)
  static Future<void> clearLocalData() async {
    try {
      await FirebaseUserPreferences.clearPreferences();
      await FirebaseProgressService.clearAllProgress();

      // Clear repetition service cache
      final repetitionService = RepetitionService();
      repetitionService.clearCache();

      print('Local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }
}
