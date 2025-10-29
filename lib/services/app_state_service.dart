import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'error_handler_service.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';

/// Centralized app state service
/// Manages app lifecycle, version migrations, and state restoration
class AppStateService extends ChangeNotifier {
  static const String _versionKey = 'app_version';
  static const String _buildNumberKey = 'app_build_number';
  static const String _lastActiveKey = 'last_active_timestamp';
  static const String _appStateKey = 'app_state';
  
  bool _isInitialized = false;
  String? _currentVersion;
  int? _currentBuildNumber;
  String? _previousVersion;
  bool _needsMigration = false;
  DateTime? _lastActive;
  
  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentVersion => _currentVersion;
  bool get needsMigration => _needsMigration;
  DateTime? get lastActive => _lastActive;

  /// Initialize the app state service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await ErrorHandlerService.logMessage('Initializing AppStateService');
      
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      _currentBuildNumber = int.tryParse(packageInfo.buildNumber);
      
      // Load previous version
      final prefs = await SharedPreferences.getInstance();
      _previousVersion = prefs.getString(_versionKey);
      final previousBuildNumber = prefs.getInt(_buildNumberKey);
      
      // Check if version changed (app was updated)
      if (_previousVersion != null && _previousVersion != _currentVersion) {
        _needsMigration = true;
        await ErrorHandlerService.logMessage(
          'App updated: $_previousVersion → $_currentVersion',
          context: 'Version Migration',
        );
      }
      
      // Check if build number changed
      if (previousBuildNumber != null && 
          _currentBuildNumber != null && 
          previousBuildNumber != _currentBuildNumber) {
        await ErrorHandlerService.logMessage(
          'Build updated: $previousBuildNumber → $_currentBuildNumber',
          context: 'Version Migration',
        );
      }
      
      // Load last active timestamp
      final lastActiveMs = prefs.getInt(_lastActiveKey);
      if (lastActiveMs != null) {
        _lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
      }
      
      // Save current version
      await prefs.setString(_versionKey, _currentVersion!);
      if (_currentBuildNumber != null) {
        await prefs.setInt(_buildNumberKey, _currentBuildNumber!);
      }
      
      // Perform migration if needed
      if (_needsMigration) {
        await _performMigration(_previousVersion!, _currentVersion!);
      }
      
      _isInitialized = true;
      notifyListeners();
      
      await ErrorHandlerService.logMessage('AppStateService initialized');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'AppStateService Initialization',
      );
      _isInitialized = true; // Continue even if initialization fails
    }
  }

  /// Perform version migration
  Future<void> _performMigration(String from, String to) async {
    try {
      await ErrorHandlerService.logMessage(
        'Starting migration from $from to $to',
        context: 'Migration',
      );
      
      // Add version-specific migrations here
      // Example: if migrating from 1.0.0 to 2.0.0, update data structures
      
      // Sync local data to Firebase after migration
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await ErrorHandlerService.logMessage(
          'Syncing data after migration',
          context: 'Migration',
        );
        await FirebaseUserPreferences.syncLocalToFirebase();
        await FirebaseProgressService.syncLocalToFirebase();
      }
      
      _needsMigration = false;
      await ErrorHandlerService.logMessage(
        'Migration completed successfully',
        context: 'Migration',
      );
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Version Migration',
        fatal: false,
      );
    }
  }

  /// Called when app is resumed
  Future<void> onAppResumed() async {
    await _updateLastActive();
    
    // Check if user session is still valid
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Reload user to check if still authenticated
        await user.reload();
        await ErrorHandlerService.logMessage('User session validated');
      } catch (e) {
        await ErrorHandlerService.logError(
          e,
          StackTrace.current,
          context: 'Session Validation',
          fatal: false,
        );
      }
    }
    
    notifyListeners();
  }

  /// Called when app is paused
  Future<void> onAppPaused() async {
    await _updateLastActive();
    await _saveAppState();
    notifyListeners();
  }

  /// Update last active timestamp
  Future<void> _updateLastActive() async {
    try {
      _lastActive = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveKey, _lastActive!.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to update last active: $e');
    }
  }

  /// Save app state for restoration
  Future<void> _saveAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appStateKey, 'paused');
      await ErrorHandlerService.logMessage('App state saved');
    } catch (e) {
      debugPrint('Failed to save app state: $e');
    }
  }

  /// Get time since last active
  Duration? getTimeSinceLastActive() {
    if (_lastActive == null) return null;
    return DateTime.now().difference(_lastActive!);
  }

  /// Check if app was inactive for too long (e.g., > 24 hours)
  bool shouldRefreshData() {
    final timeSinceActive = getTimeSinceLastActive();
    if (timeSinceActive == null) return true;
    return timeSinceActive.inHours > 24;
  }

  /// Force refresh of all data
  Future<void> refreshData() async {
    try {
      await ErrorHandlerService.logMessage('Refreshing app data');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        // Reload preferences
        await FirebaseUserPreferences.loadPreferences();
        
        // Reload progress
        await FirebaseProgressService.loadAllProgress();
      }
      
      await ErrorHandlerService.logMessage('App data refreshed');
      notifyListeners();
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Data Refresh',
        fatal: false,
      );
    }
  }

  /// Clear all app state (for logout/reset)
  Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep version info but clear other state
      final version = prefs.getString(_versionKey);
      final buildNumber = prefs.getInt(_buildNumberKey);
      
      await prefs.clear();
      
      // Restore version info
      if (version != null) {
        await prefs.setString(_versionKey, version);
      }
      if (buildNumber != null) {
        await prefs.setInt(_buildNumberKey, buildNumber);
      }
      
      _lastActive = null;
      notifyListeners();
      
      await ErrorHandlerService.logMessage('App state cleared');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Clear State',
      );
    }
  }

  /// Log app state for debugging
  Future<void> logState() async {
    await ErrorHandlerService.setCustomKey('app_version', _currentVersion ?? 'unknown');
    await ErrorHandlerService.setCustomKey('app_build', _currentBuildNumber ?? 0);
    await ErrorHandlerService.setCustomKey(
      'last_active',
      _lastActive?.toIso8601String() ?? 'never',
    );
  }
}