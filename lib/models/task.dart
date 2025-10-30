import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String text;

  @HiveField(1)
  String status = 'pending'; // e.g., 'pending', 'done', 'migrated', 'canceled'

  @HiveField(2)
  late DateTime dueDate;

  @HiveField(3)
  List<String> tags = [];

  @HiveField(4)
  String category = 'task'; // e.g., 'task', 'event'

  @HiveField(5)
  String? note; // Optional short note for additional context
  
  @HiveField(6)
  String? googleCalendarEventId; // Google Calendar event ID if synced
}
