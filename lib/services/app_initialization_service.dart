import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'repetition_service.dart';
import 'error_handler_service.dart';

/// Enhanced app initialization service with robust error handling
class AppInitializationService {
  static bool _initialized = false;
  static bool _isInitializing = false;

  /// Initialize the app services
  static Future<void> initialize() async {
    if (_initialized) {
      await ErrorHandlerService.logMessage('AppInitService already initialized');
      return;
    }

    if (_isInitializing) {
      await ErrorHandlerService.logMessage('AppInitService initialization in progress');
      return;
    }

    _isInitializing = true;

    try {
      await ErrorHandlerService.logMessage('Starting app initialization');

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );
      
      await ErrorHandlerService.logMessage(
        'Network status: ${isOnline ? "Online" : "Offline"}',
      );
      await ErrorHandlerService.setCustomKey('network_status', isOnline ? 'online' : 'offline');

      // Initialize Firebase Auth listener
      FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);

      // If user is already logged in and not anonymous, sync data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ErrorHandlerService.setUserIdentifier(
          user.isAnonymous ? 'anonymous_${user.uid}' : user.uid,
        );
        
        if (!user.isAnonymous && isOnline) {
          await ErrorHandlerService.logMessage('Syncing data for authenticated user');
          await _syncDataToFirebase();
        } else if (!isOnline) {
          await ErrorHandlerService.logMessage('Offline mode - skipping sync');
        } else {
          await ErrorHandlerService.logMessage('Anonymous user - skipping sync');
        }
      } else {
        await ErrorHandlerService.logMessage('No user logged in');
      }

      _initialized = true;
      _isInitializing = false;
      
      await ErrorHandlerService.logMessage('App initialization completed successfully');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'App Initialization',
        fatal: false,
      );
      
      // Continue with app initialization even if Firebase fails
      _initialized = true;
      _isInitializing = false;
    }
  }

  /// Handle authentication state changes
  static Future<void> _handleAuthStateChange(User? user) async {
    try {
      if (user != null) {
        await ErrorHandlerService.logAuthEvent(
          'Auth state changed',
          success: true,
        );
        
        await ErrorHandlerService.setUserIdentifier(
          user.isAnonymous ? 'anonymous_${user.uid}' : user.uid,
        );
        
        if (!user.isAnonymous) {
          // Check network before syncing
          final connectivityResult = await Connectivity().checkConnectivity();
          final isOnline = connectivityResult.any((result) => 
            result != ConnectivityResult.none
          );
          
          if (isOnline) {
            await ErrorHandlerService.logMessage('User logged in - syncing data');
            await _syncDataToFirebase();
          } else {
            await ErrorHandlerService.logMessage('User logged in - offline, sync deferred');
          }
        }
      } else {
        await ErrorHandlerService.logAuthEvent(
          'User logged out',
          success: true,
        );
        await ErrorHandlerService.clearUserIdentifier();
      }
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Auth State Change',
        fatal: false,
      );
    }
  }

  /// Sync local data to Firebase with retry logic
  static Future<void> _syncDataToFirebase() async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        await ErrorHandlerService.logSyncEvent('Starting data sync');

        // Sync user preferences
        await FirebaseUserPreferences.syncLocalToFirebase()
            .timeout(const Duration(seconds: 10));
        
        await ErrorHandlerService.logSyncEvent('Preferences synced');

        // Sync progress data
        await FirebaseProgressService.syncLocalToFirebase()
            .timeout(const Duration(seconds: 15));
        
        await ErrorHandlerService.logSyncEvent('Progress synced');

        await ErrorHandlerService.logMessage('Data sync completed successfully');
        return; // Success - exit retry loop
        
      } catch (e, stack) {
        retryCount++;
        
        if (retryCount > maxRetries) {
          await ErrorHandlerService.logError(
            e,
            stack,
            context: 'Data Sync Failed (max retries)',
            fatal: false,
            additionalInfo: {'retry_count': retryCount},
          );
          // Don't throw - allow app to continue with local data
          return;
        }
        
        await ErrorHandlerService.logMessage(
          'Sync attempt $retryCount failed, retrying...',
        );
        
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  /// Get initialization status
  static bool get isInitialized => _initialized;

  /// Force re-initialization (useful for testing or error recovery)
  static Future<void> reinitialize() async {
    await ErrorHandlerService.logMessage('Forcing re-initialization');
    _initialized = false;
    _isInitializing = false;
    await initialize();
  }

  /// Prepare user data after login with timeout protection
  static Future<void> prepareUserData() async {
    try {
      await ErrorHandlerService.logMessage('Preparing user data');

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );

      if (!isOnline) {
        await ErrorHandlerService.logMessage('Offline - using cached data');
        return;
      }

      // Load all progress data into cache with timeout
      final repetitionService = RepetitionService();
      await repetitionService.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          ErrorHandlerService.logTimeout('RepetitionService initialization', 
            const Duration(seconds: 8));
        },
      );

      await ErrorHandlerService.logMessage('User data prepared successfully');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Prepare User Data',
        fatal: false,
      );
      // Don't throw - allow app to continue
    }
  }

  /// Clear all local data (useful for logout/reset)
  static Future<void> clearLocalData() async {
    try {
      await ErrorHandlerService.logMessage('Clearing local data');

      await FirebaseUserPreferences.clearPreferences();
      await FirebaseProgressService.clearAllProgress();

      // Clear repetition service cache
      final repetitionService = RepetitionService();
      repetitionService.clearCache();

      await ErrorHandlerService.logMessage('Local data cleared successfully');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Clear Local Data',
        fatal: false,
      );
    }
  }

  /// Sync data manually (useful for pull-to-refresh)
  static Future<bool> manualSync() async {
    try {
      await ErrorHandlerService.logMessage('Manual sync triggered');

      // Check network
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );

      if (!isOnline) {
        await ErrorHandlerService.logMessage('Manual sync failed: offline');
        return false;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        await ErrorHandlerService.logMessage('Manual sync skipped: no auth');
        return false;
      }

      await _syncDataToFirebase();
      await ErrorHandlerService.logMessage('Manual sync completed');
      return true;
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Manual Sync',
        fatal: false,
      );
      return false;
    }
  }

  /// Check app health status
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );

      return {
        'initialized': _initialized,
        'has_user': user != null,
        'is_anonymous': user?.isAnonymous ?? true,
        'is_online': isOnline,
        'user_id': user?.uid ?? 'none',
      };
    } catch (e) {
      return {
        'initialized': _initialized,
        'error': e.toString(),
      };
    }
  }
}