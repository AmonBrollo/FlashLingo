import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized error handling service
/// Logs errors to Crashlytics and console with context
class ErrorHandlerService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Log an error with context to Crashlytics
  static Future<void> logError(
    dynamic error,
    StackTrace? stack, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Log to console
      debugPrint('❌ ERROR [$context]: $error');
      if (stack != null) {
        debugPrint('Stack trace: $stack');
      }

      // Set custom keys for better debugging
      if (context != null) {
        await _crashlytics.setCustomKey('error_context', context);
      }
      
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Record to Crashlytics
      await _crashlytics.recordError(
        error,
        stack,
        reason: context,
        fatal: fatal,
      );

      // Log message to Crashlytics breadcrumbs
      await _crashlytics.log('Error in $context: ${error.toString()}');
    } catch (e) {
      // If Crashlytics fails, at least log to console
      debugPrint('⚠️ Failed to log error to Crashlytics: $e');
    }
  }

  /// Handle Flutter framework errors
  static void handleFlutterError(FlutterErrorDetails details) {
    // Log to console
    FlutterError.presentError(details);
    
    // Log to Crashlytics
    logError(
      details.exception,
      details.stack,
      context: details.context?.toString() ?? 'Flutter Error',
      fatal: details.silent ? false : true,
      additionalInfo: {
        'library': details.library ?? 'unknown',
      },
    );
  }

  /// Log a non-fatal message (breadcrumb)
  static Future<void> logMessage(String message, {String? context}) async {
    try {
      final logMessage = context != null ? '[$context] $message' : message;
      await _crashlytics.log(logMessage);
      debugPrint('📝 $logMessage');
    } catch (e) {
      debugPrint('⚠️ Failed to log message: $e');
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUserIdentifier(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      debugPrint('👤 User identifier set: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to set user identifier: $e');
    }
  }

  /// Clear user identifier (on logout)
  static Future<void> clearUserIdentifier() async {
    try {
      await _crashlytics.setUserIdentifier('');
      debugPrint('👤 User identifier cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear user identifier: $e');
    }
  }

  /// Set custom key-value pairs for debugging
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to set custom key: $e');
    }
  }

  /// Track screen views
  static Future<void> logScreenView(String screenName) async {
    await logMessage('Screen: $screenName', context: 'Navigation');
  }

  /// Track user actions
  static Future<void> logUserAction(String action, {Map<String, dynamic>? params}) async {
    String message = 'Action: $action';
    if (params != null && params.isNotEmpty) {
      message += ' | ${params.toString()}';
    }
    await logMessage(message, context: 'User Action');
  }

  /// Log authentication events
  static Future<void> logAuthEvent(String event, {bool success = true}) async {
    await logMessage(
      '$event: ${success ? 'Success' : 'Failed'}',
      context: 'Authentication',
    );
  }

  /// Log data sync events
  static Future<void> logSyncEvent(String event, {int? itemCount}) async {
    String message = 'Sync: $event';
    if (itemCount != null) {
      message += ' ($itemCount items)';
    }
    await logMessage(message, context: 'Data Sync');
  }

  /// Create error report for timeouts
  static Future<void> logTimeout(String operation, Duration timeout) async {
    await logError(
      TimeoutException('$operation timed out after ${timeout.inSeconds}s'),
      StackTrace.current,
      context: 'Timeout',
      fatal: false,
      additionalInfo: {
        'operation': operation,
        'timeout_seconds': timeout.inSeconds,
      },
    );
  }

  /// Log network errors
  static Future<void> logNetworkError(dynamic error, String operation) async {
    await logError(
      error,
      StackTrace.current,
      context: 'Network Error',
      fatal: false,
      additionalInfo: {
        'operation': operation,
      },
    );
  }

  /// Test crash (for testing Crashlytics integration)
  static Future<void> testCrash() async {
    _crashlytics.crash();
  }

  /// Check if crash reporting is enabled
  static Future<bool> isCrashlyticsEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      return false;
    }
  }
}

/// TimeoutException for timeout errors
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}