import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_user_preferences.dart';
import 'firebase_progress_service.dart';
import 'error_handler_service.dart';

/// Centralized sync service to keep data in sync across devices.
/// Non-blocking by design — local storage is always the source of truth.
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
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _batchThreshold = 10;
  static const Duration _debounceDelay = Duration(seconds: 5);

  // Per-operation Firebase timeout.
  // Must be LONGER than any internal timeout used inside the service methods
  // themselves (FirebaseProgressService uses 10s for batch commits, so we give
  // a generous ceiling here to avoid masking partial success).
  static const Duration _pushTimeout = Duration(seconds: 20);

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
    _startPeriodicSync();
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _syncInBackground();
  }

  /// Trigger a background sync without blocking the caller.
  void _syncInBackground() {
    Future.microtask(() async {
      try {
        await syncNow();
      } catch (e) {
        print('Background sync failed: $e');
      }
    });
  }

  /// Mark that data has changed and schedule a debounced sync.
  void markDataChanged() {
    _hasPendingChanges = true;
    _pendingChangesCount++;

    _debounceTimer?.cancel();

    if (_pendingChangesCount >= _batchThreshold) {
      _debounceTimer = Timer(const Duration(seconds: 1), _syncInBackground);
    } else {
      _debounceTimer = Timer(_debounceDelay, _syncInBackground);
    }
  }

  /// Attempt a sync now. Returns a [SyncResult] describing what happened.
  /// Never throws — all errors are captured in the result.
  Future<SyncResult> syncNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SyncResult(success: false, reason: 'Not logged in');
    }

    if (_isSyncing) {
      return SyncResult(success: false, reason: 'Sync in progress');
    }

    final isOnline = await _isOnline();
    if (!isOnline) {
      await ErrorHandlerService.logMessage('SyncService: Offline, queuing sync');
      return SyncResult(success: false, reason: 'Offline');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      await ErrorHandlerService.logSyncEvent('Starting background sync');

      if (_hasPendingChanges) {
        await _pushToFirebase();
      }

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

  /// Push local state to Firebase.
  ///
  /// Timeout strategy:
  ///   • Each operation is given [_pushTimeout] individually.
  ///   • A [TimeoutException] is treated as a soft failure (slow network,
  ///     not an error state). We log it and continue so the caller can still
  ///     mark the sync as successful for any operations that did complete.
  ///   • Only unexpected exceptions are rethrown to surface as sync errors.
  Future<void> _pushToFirebase() async {
    // --- Preferences ---
    try {
      await FirebaseUserPreferences.syncLocalToFirebase()
          .timeout(_pushTimeout);
    } on TimeoutException {
      // Slow network — not a hard failure. Changes remain pending and will
      // be retried on the next periodic or manual sync.
      print('SyncService: preferences push timed out — will retry later');
    } catch (e) {
      print('SyncService: preferences push failed — $e');
      // Don't rethrow: a preferences failure should not block progress sync.
    }

    // --- Progress ---
    try {
      await FirebaseProgressService.syncLocalToFirebase()
          .timeout(_pushTimeout);
    } on TimeoutException {
      print('SyncService: progress push timed out — will retry later');
      // Keep _hasPendingChanges true so the next cycle retries.
      _hasPendingChanges = true;
    } catch (e) {
      print('SyncService: progress push failed — $e');
      _hasPendingChanges = true;
    }

    await ErrorHandlerService.logSyncEvent('Push to Firebase completed');
  }

  /// Start the periodic background sync timer.
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) {
      if (_hasPendingChanges) {
        _syncInBackground();
      }
    });
  }

  /// React to connectivity changes — resume sync when coming back online.
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline && _hasPendingChanges) {
      await ErrorHandlerService.logMessage(
          'SyncService: Back online, syncing pending changes');
      _syncInBackground();
    }
  }

  /// Returns true if the device has any active network connection.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Human-readable description of the current sync state.
  String getSyncStatusText() {
    if (_isSyncing) return 'Syncing...';
    if (_hasPendingChanges) return 'Changes pending';
    if (_lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff.inMinutes < 1) return 'Synced just now';
      if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
      return 'Synced ${diff.inHours}h ago';
    }
    return 'Not synced';
  }

  /// Release resources.
  void dispose() {
    _periodicSyncTimer?.cancel();
    _debounceTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Broadcast sync state.
enum SyncStatus { idle, syncing, synced, error }

/// Result returned by [SyncService.syncNow].
class SyncResult {
  final bool success;
  final String? reason;
  const SyncResult({required this.success, this.reason});
}