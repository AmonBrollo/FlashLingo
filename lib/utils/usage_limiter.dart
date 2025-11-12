import 'package:shared_preferences/shared_preferences.dart';

class UsageLimiter {
  static const _usedKey = 'flashcards_used';
  static const _lastResetKey = 'last_reset_timestamp';
  static const int _limit = 30;
  static const Duration _cooldown = Duration(hours: 0);

  Future<bool> canStudy() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastResetMillis = prefs.getInt(_lastResetKey);
    final used = prefs.getInt(_usedKey) ?? 0;

    if (lastResetMillis != null) {
      final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);

      if (now.difference(lastReset) >= _cooldown) {
        await _resetUsage(prefs, now);
        return true;
      }

      return used < _limit;
    }

    await _resetUsage(prefs, now);
    return true;
  }

  Future<void> markStudied() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_usedKey) ?? 0;
    await prefs.setInt(_usedKey, used + 1);
  }

  Future<Duration> timeUntilReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetMillis = prefs.getInt(_lastResetKey);

    if (lastResetMillis == null) return Duration.zero;

    final lastReset = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);
    final now = DateTime.now();
    final elapsed = now.difference(lastReset);

    return _cooldown - elapsed;
  }

  Future<void> _resetUsage(SharedPreferences prefs, DateTime now) async {
    await prefs.setInt(_usedKey, 0);
    await prefs.setInt(_lastResetKey, now.millisecondsSinceEpoch);
  }
}
