import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for Google Calendar sync setting
final googleCalendarSyncProvider = StateNotifierProvider<GoogleCalendarSyncNotifier, bool>((ref) {
  return GoogleCalendarSyncNotifier();
});

class GoogleCalendarSyncNotifier extends StateNotifier<bool> {
  static const String _key = 'google_calendar_sync_enabled';

  GoogleCalendarSyncNotifier() : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    state = enabled;
  }
}
