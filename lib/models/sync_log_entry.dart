import 'package:hive/hive.dart';

part 'sync_log_entry.g.dart';

@HiveType(typeId: 4)
class SyncLogEntry extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String type; // 'upload', 'download', 'auto', 'manual', 'startup'

  @HiveField(2)
  bool success;

  @HiveField(3)
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
