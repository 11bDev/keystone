import 'package:isar/isar.dart';

part 'sync_log_entry.g.dart';

@collection
class SyncLogEntry {
  Id id = Isar.autoIncrement;

  DateTime timestamp;

  String type; // 'upload', 'download', 'auto', 'manual', 'startup'

  bool success;

  String? errorMessage;

  SyncLogEntry({
    required this.timestamp,
    required this.type,
    required this.success,
    this.errorMessage,
  });

  String get displayType {
    switch (type) {
      case 'upload':
        return 'Upload to Drive';
      case 'download':
        return 'Download from Drive';
      case 'auto':
        return 'Auto Sync';
      case 'manual':
        return 'Manual Sync';
      case 'startup':
        return 'App Startup Sync';
      default:
        return type;
    }
  }
}
