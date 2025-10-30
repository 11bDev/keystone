import 'package:keystone/services/google_calendar_service.dart';

/// Common interface for sync services
abstract class SyncServiceInterface {
  Future<bool> signIn();
  Future<void> signOut();
  bool get isSignedIn;
  String? get userEmail;
  Future<void> syncToGoogleDrive();
  Future<void> syncFromGoogleDrive();
  Future<DateTime?> getLastBackupTime();
  Future<String> exportToLocalFile();
  Future<void> importFromLocalFile(String filePath);
  GoogleCalendarService get calendarService;
}
