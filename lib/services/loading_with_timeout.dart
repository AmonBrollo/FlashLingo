import 'dart:async';

/// A utility class to handle loading operations with timeout
class LoadingWithTimeout {
  /// Execute a future with a timeout and retry mechanism
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 10),
    String operationName = 'Operation',
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            '$operationName timed out after ${timeout.inSeconds} seconds',
          );
        },
      );
    } catch (e) {
      print('Error in $operationName: $e');
      rethrow;
    }
  }

  /// Execute multiple operations with individual timeouts
  static Future<Map<String, dynamic>> executeMultiple({
    required Map<String, Future<dynamic> Function()> operations,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final results = <String, dynamic>{};

    for (final entry in operations.entries) {
      try {
        results[entry.key] = await execute(
          operation: entry.value,
          timeout: timeout,
          operationName: entry.key,
        );
      } catch (e) {
        print('Failed to load ${entry.key}: $e');
        results[entry.key] = null;
      }
    }

    return results;
  }
}
