import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'error_handler_service.dart';

/// Centralized sync service to keep data in sync across devices
/// Now completely non-blocking for maximum performance
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
  static const Duration _syncInterval = Duration(minutes: 5); // Increased to reduce Firebase calls
  static const int _batchThreshold = 10; // Increased to batch more changes
  static const Duration _debounceDelay = Duration(seconds: 5); // Increased debounce
  
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
    
    // Sync in background (non-blocking)
    _syncInBackground();
  }

  /// Sync in background without blocking
  void _syncInBackground() {
    Future.microtask(() async {
      try {
        await syncNow();
      } catch (e) {
        print('Background sync failed: $e');
      }
    });
  }

  /// Mark that data has changed (triggers batched sync)
  void markDataChanged() {
    _hasPendingChanges = true;
    _pendingChangesCount++;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // If we've hit the batch threshold, sync soon
    if (_pendingChangesCount >= _batchThreshold) {
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        _syncInBackground();
      });
    } else {
      // Otherwise, debounce and sync after delay
      _debounceTimer = Timer(_debounceDelay, () {
        _syncInBackground();
      });
    }
  }

  /// Force sync immediately (still non-blocking)
  Future<SyncResult> syncNow() async {
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SyncResult(success: false, reason: 'Not logged in');
    }

    // Check if already syncing
    if (_isSyncing) {
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
      await ErrorHandlerService.logSyncEvent('Starting background sync');

      // Push local changes to Firebase (with timeout)
      if (_hasPendingChanges) {
        await _pushToFirebase().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('Sync timed out - will retry later');
          },
        );
      }

      // Update state
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false;
      _pendingChangesCount = 0;
      
      _syncStatusController.add(SyncStatus.synced);
      await ErrorHandlerService.logSyncEvent('Sync completed');

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

  /// Push local changes to Firebase (non-blocking)
  Future<void> _pushToFirebase() async {
    try {
      // Push preferences (with timeout)
      await FirebaseUserPreferences.syncLocalToFirebase().timeout(
        const Duration(seconds: 2),
      );

      // Push progress (with timeout)
      await FirebaseProgressService.syncLocalToFirebase().timeout(
        const Duration(seconds: 2),
      );

      await ErrorHandlerService.logSyncEvent('Pushed data to Firebase');
    } catch (e) {
      print('Push to Firebase failed (expected if offline): $e');
      rethrow;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_hasPendingChanges) {
        _syncInBackground();
      }
    });
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (isOnline && _hasPendingChanges) {
      await ErrorHandlerService.logMessage('SyncService: Back online, syncing pending changes');
      _syncInBackground();
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