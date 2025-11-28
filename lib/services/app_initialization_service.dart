import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'repetition_service.dart';
import 'error_handler_service.dart';
import 'sync_service.dart';

/// Enhanced app initialization service with robust error handling
class AppInitializationService {
  static bool _initialized = false;
  static bool _isInitializing = false;

  /// Initialize the app services (NON-BLOCKING)
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
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.none],
      );
      
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );
      
      await ErrorHandlerService.logMessage(
        'Network status: ${isOnline ? "Online" : "Offline"}',
      );
      await ErrorHandlerService.setCustomKey('network_status', isOnline ? 'online' : 'offline');

      // Initialize sync service first (with timeout)
      try {
        await SyncService().initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            ErrorHandlerService.logMessage('SyncService initialization timed out');
          },
        );
      } catch (e, stack) {
        await ErrorHandlerService.logError(
          e,
          stack,
          context: 'SyncService Init',
          fatal: false,
        );
      }

      // DON'T initialize RepetitionService here - let it load on-demand
      await ErrorHandlerService.logMessage('RepetitionService will load on-demand');

      // Initialize Firebase Auth listener
      FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);

      // If user is already logged in, sync in background (NON-BLOCKING)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ErrorHandlerService.setUserIdentifier(
          user.isAnonymous ? 'anonymous_${user.uid}' : user.uid,
        );
        
        if (isOnline) {
          await ErrorHandlerService.logMessage('User logged in - scheduling background sync');
          // Don't await - sync in background
          SyncService().syncNow().then((result) {
            ErrorHandlerService.logMessage('Background sync completed');
          }, onError: (e, stack) {
            ErrorHandlerService.logError(
              e,
              stack,
              context: 'Background Sync',
              fatal: false,
            );
          });
        } else {
          await ErrorHandlerService.logMessage('Offline mode - sync deferred');
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
      
      // Continue with app initialization even if some services fail
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
        
        // Check network before syncing
        final connectivityResult = await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 2),
          onTimeout: () => [ConnectivityResult.none],
        );
        
        final isOnline = connectivityResult.any((result) => 
          result != ConnectivityResult.none
        );
        
        if (isOnline) {
          await ErrorHandlerService.logMessage('User logged in - syncing data');
          // Don't await - sync in background
          SyncService().syncNow().then((result) {
            // Sync completed
          }, onError: (e, stack) {
            ErrorHandlerService.logError(
              e,
              stack,
              context: 'Auth State Sync',
              fatal: false,
            );
          });
          
          // Reload RepetitionService cache with new user data (in background)
          RepetitionService().reloadCache().catchError((e, stack) {
            ErrorHandlerService.logError(
              e,
              stack,
              context: 'RepetitionService Reload',
              fatal: false,
            );
          });
        } else {
          await ErrorHandlerService.logMessage('User logged in - offline, sync deferred');
          SyncService().markDataChanged(); // Queue for later sync
        }
      } else {
        await ErrorHandlerService.logAuthEvent(
          'User logged out',
          success: true,
        );
        await ErrorHandlerService.clearUserIdentifier();
        
        // Clear RepetitionService cache on logout
        RepetitionService().clearCache();
        
        // Clear memory cache in progress service
        FirebaseProgressService.clearMemoryCache();
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
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 2),
        onTimeout: () => [ConnectivityResult.none],
      );
      
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );

      if (!isOnline) {
        await ErrorHandlerService.logMessage('Offline - using cached data');
        return;
      }

      // Reload RepetitionService cache with shorter timeout
      final repetitionService = RepetitionService();
      await repetitionService.reloadCache().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          ErrorHandlerService.logTimeout('RepetitionService reload', 
            const Duration(seconds: 5));
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
      RepetitionService().clearCache();

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

      final result = await SyncService().syncNow().timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          await ErrorHandlerService.logTimeout('Manual sync', const Duration(seconds: 10));
          return SyncResult(success: false, reason: 'Timeout');
        },
      );
      
      if (result.success) {
        await ErrorHandlerService.logMessage('Manual sync completed');
        // Reload cache after successful sync
        await RepetitionService().reloadCache().timeout(
          const Duration(seconds: 5),
          onTimeout: () async {
            await ErrorHandlerService.logMessage('Cache reload timed out after manual sync');
          },
        );
        return true;
      } else {
        await ErrorHandlerService.logMessage('Manual sync failed: ${result.reason}');
        return false;
      }
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
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 2),
        onTimeout: () => [ConnectivityResult.none],
      );
      
      final isOnline = connectivityResult.any((result) => 
        result != ConnectivityResult.none
      );

      return {
        'initialized': _initialized,
        'has_user': user != null,
        'is_anonymous': user?.isAnonymous ?? true,
        'is_online': isOnline,
        'user_id': user?.uid ?? 'none',
        'cache_loaded': RepetitionService().isCacheLoaded,
        'crashlytics_enabled': await ErrorHandlerService.isCrashlyticsEnabled(),
      };
    } catch (e) {
      return {
        'initialized': _initialized,
        'error': e.toString(),
      };
    }
  }
}