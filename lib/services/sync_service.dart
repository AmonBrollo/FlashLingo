import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'error_handler_service.dart';

/// Centralized sync service to keep data in sync across devices
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Sync state
  bool _isSyncing = false;
  bool _hasPendingChanges = false;
  DateTime? _lastSyncTime;
  Timer? _periodicSyncTimer;
  int _pendingChangesCount = 0;

  // Sync settings
  static const Duration _syncInterval = Duration(minutes: 2);
  static const int _batchThreshold = 5; // Sync after 5 changes
  static const Duration _debounceDelay = Duration(seconds: 2);
  
  Timer? _debounceTimer;
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();

  // Public API
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;
  bool get hasPendingChanges => _hasPendingChanges;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize sync service
  Future<void> initialize() async {
    await ErrorHandlerService.logMessage('SyncService: Initializing');
    
    // Start periodic sync timer
    _startPeriodicSync();
    
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Sync immediately on initialization
    await syncNow();
  }

  /// Mark that data has changed (triggers batched sync)
  void markDataChanged() {
    _hasPendingChanges = true;
    _pendingChangesCount++;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // If we've hit the batch threshold, sync immediately
    if (_pendingChangesCount >= _batchThreshold) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        syncNow();
      });
    } else {
      // Otherwise, debounce and sync after delay
      _debounceTimer = Timer(_debounceDelay, () {
        syncNow();
      });
    }
  }

  /// Force sync immediately
  Future<SyncResult> syncNow() async {
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await ErrorHandlerService.logMessage('SyncService: No user, skipping sync');
      return SyncResult(success: false, reason: 'Not logged in');
    }

    // Check if already syncing
    if (_isSyncing) {
      await ErrorHandlerService.logMessage('SyncService: Already syncing');
      return SyncResult(success: false, reason: 'Sync in progress');
    }

    // Check connectivity
    final isOnline = await _isOnline();
    if (!isOnline) {
      await ErrorHandlerService.logMessage('SyncService: Offline, queuing sync');
      return SyncResult(success: false, reason: 'Offline');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    
    try {
      await ErrorHandlerService.logSyncEvent('Starting full sync');

      // 1. Pull latest data from Firebase first
      await _pullFromFirebase();

      // 2. Push local changes to Firebase
      if (_hasPendingChanges) {
        await _pushToFirebase();
      }

      // Update state
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false;
      _pendingChangesCount = 0;
      
      _syncStatusController.add(SyncStatus.synced);
      await ErrorHandlerService.logSyncEvent('Sync completed successfully');

      return SyncResult(success: true);
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Sync Failed',
        fatal: false,
      );
      
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(success: false, reason: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull latest data from Firebase
  Future<void> _pullFromFirebase() async {
    try {
      await ErrorHandlerService.logMessage('SyncService: Pulling data from Firebase');

      // Pull preferences
      final prefs = await FirebaseUserPreferences.loadPreferences();
      await ErrorHandlerService.logMessage(
        'SyncService: Pulled preferences (base: ${prefs['baseLanguage']})',
      );

      // Pull progress
      final progress = await FirebaseProgressService.loadAllProgress();
      await ErrorHandlerService.logSyncEvent(
        'Pulled progress',
        itemCount: progress.length,
      );
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Pull from Firebase',
        fatal: false,
      );
      rethrow;
    }
  }

  /// Push local changes to Firebase
  Future<void> _pushToFirebase() async {
    try {
      await ErrorHandlerService.logMessage('SyncService: Pushing data to Firebase');

      // Push preferences
      await FirebaseUserPreferences.syncLocalToFirebase();

      // Push progress
      await FirebaseProgressService.syncLocalToFirebase();

      await ErrorHandlerService.logSyncEvent('Pushed all data to Firebase');
    } catch (e) {
      await ErrorHandlerService.logError(
        e,
        StackTrace.current,
        context: 'Push to Firebase',
        fatal: false,
      );
      rethrow;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_hasPendingChanges) {
        syncNow();
      }
    });
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (isOnline && _hasPendingChanges) {
      await ErrorHandlerService.logMessage('SyncService: Back online, syncing pending changes');
      await syncNow();
    }
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Get sync status text
  String getSyncStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (_hasPendingChanges) {
      return 'Changes pending';
    } else if (_lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff.inMinutes < 1) {
        return 'Synced just now';
      } else if (diff.inMinutes < 60) {
        return 'Synced ${diff.inMinutes}m ago';
      } else {
        return 'Synced ${diff.inHours}h ago';
      }
    } else {
      return 'Not synced';
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _debounceTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

/// Sync result
class SyncResult {
  final bool success;
  final String? reason;

  SyncResult({required this.success, this.reason});
}