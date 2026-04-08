import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'firebase_progress_service.dart';

/// Service responsible for scheduling local push notifications
/// when Leitner box cards become due.
///
/// Scheduling logic:
/// - One notification per box (1–5) per unique due date
/// - Fires 1 hour before nextReview (midpoint of the 2-hour grace period)
/// - Boxes 0 and -1 are excluded (always available, no scheduled time)
///
/// Notification IDs are deterministic: box * 1000 + dayOfYear
/// so rescheduling is idempotent (cancels + rewrites same IDs).
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefKey = 'notifications_enabled';
  static const String _channelId = 'flashlingo_due_cards';
  static const String _channelName = 'Due Cards';
  static const String _channelDescription =
      'Notifications when flashcards are ready for review';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true;

  // Debounce timer for reschedule calls triggered by card saves
  Timer? _debounceTimer;

  // ─── Public API ─────────────────────────────────────────────────────────────

  bool get isEnabled => _enabled;

  /// Initialize the plugin, timezone data, and request permissions.
  /// Call once from main.dart after Firebase is ready.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database (required by flutter_local_notifications)
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    // Load persisted preference
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
    } catch (e) {
      print('NotificationService: could not load preference: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Request Android 13+ POST_NOTIFICATIONS permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    print('NotificationService initialized (enabled: $_enabled)');

    if (_enabled) {
      await scheduleNotificationsFromCache();
    }
  }

  /// Enable or disable notifications. Persists the preference.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e) {
      print('NotificationService: could not save preference: $e');
    }

    if (value) {
      await scheduleNotificationsFromCache();
    } else {
      await cancelAllNotifications();
    }
  }

  /// Debounced reschedule — safe to call after every card save.
  /// Waits 500 ms before actually rescheduling so rapid swipes
  /// are batched into a single reschedule call.
  void rescheduleDebounced() {
    if (!_enabled) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      scheduleNotificationsFromCache();
    });
  }

  /// Reschedule immediately (used on app resume).
  Future<void> rescheduleFromCache() async {
    if (!_enabled) return;
    await scheduleNotificationsFromCache();
  }

  /// Cancel every pending notification.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print('NotificationService: all notifications cancelled');
  }

  // ─── Core scheduling logic ───────────────────────────────────────────────────

  /// Read the in-memory progress cache, group cards by (box, due-date),
  /// and schedule one notification per group.
  Future<void> scheduleNotificationsFromCache() async {
    if (!_initialized) return;

    // Cancel all existing scheduled notifications first (idempotent)
    await _plugin.cancelAll();

    // Read from the memory cache — no extra Firebase call
    final allProgress = await FirebaseProgressService.loadAllProgress();

    if (allProgress.isEmpty) return;

    final now = DateTime.now();

    // Map of notificationId → pending notification
    // ID = box * 1000 + dayOfYear  (unique per box per calendar day)
    final Map<int, _PendingNotification> pending = {};

    for (final entry in allProgress.entries) {
      final progress = entry.value;

      // Only schedule for boxes 1–5
      if (progress.box < 1 || progress.box > 5) continue;

      // Fire 1 hour before nextReview (midpoint of the 2-hour grace period)
      final triggerTime =
          progress.nextReview.subtract(const Duration(hours: 1));

      // Skip if the trigger time is already in the past
      if (triggerTime.isBefore(now)) continue;

      final dayOfYear = _dayOfYear(triggerTime);
      final notifId = progress.box * 1000 + dayOfYear;

      // Keep only the earliest trigger for the same (box, day) bucket
      if (!pending.containsKey(notifId) ||
          triggerTime.isBefore(pending[notifId]!.scheduledTime)) {
        pending[notifId] = _PendingNotification(
          id: notifId,
          box: progress.box,
          scheduledTime: triggerTime,
        );
      }
    }

    if (pending.isEmpty) {
      print('NotificationService: no future due cards to schedule');
      return;
    }

    for (final notif in pending.values) {
      await _scheduleNotification(notif);
    }

    print('NotificationService: scheduled ${pending.length} notification(s)');
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _scheduleNotification(_PendingNotification notif) async {
    final title = '📚 Box ${notif.box} cards are ready!';
    final body = _bodyForBox(notif.box);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = _toTZDateTime(notif.scheduledTime);

    try {
      await _plugin.zonedSchedule(
        notif.id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('NotificationService: failed to schedule notif ${notif.id}: $e');
    }
  }

  String _bodyForBox(int box) {
    switch (box) {
      case 1:
        return 'Your daily review cards are waiting for you.';
      case 2:
        return 'Your 3-day review cards are ready.';
      case 3:
        return 'Your weekly review cards are due.';
      case 4:
        return 'Your 2-week review cards are ready.';
      case 5:
        return 'Your monthly mastery cards are due for review.';
      default:
        return 'You have cards ready for review.';
    }
  }

  /// Convert a [DateTime] to a tz.TZDateTime in the device's local timezone.
  tz.TZDateTime _toTZDateTime(DateTime dt) {
    return tz.TZDateTime(
      tz.local,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }

  int _dayOfYear(DateTime dt) {
    final start = DateTime(dt.year, 1, 1);
    return dt.difference(start).inDays + 1;
  }
}

class _PendingNotification {
  final int id;
  final int box;
  final DateTime scheduledTime;

  const _PendingNotification({
    required this.id,
    required this.box,
    required this.scheduledTime,
  });
}