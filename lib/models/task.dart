import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @HiveField(7)
  DateTime? lastModified; // Local timestamp for conflict resolution

  // Firestore sync support
  String? firestoreId; // Firestore document ID for syncing

  /// Create Task from Firestore document
  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final task = Task();
    task.firestoreId = doc.id;
    task.text = data['text'] as String;
    task.status = data['status'] as String? ?? 'pending';
    task.dueDate = (data['dueDate'] as Timestamp).toDate();
    task.tags = List<String>.from(data['tags'] as List? ?? []);
    task.category = data['category'] as String? ?? 'task';
    task.note = data['note'] as String?;
    task.googleCalendarEventId = data['googleCalendarEventId'] as String?;
    task.lastModified = data['lastModified'] != null 
        ? (data['lastModified'] as Timestamp).toDate()
        : null;
    return task;
  }

  /// Convert Task to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
      'tags': tags,
      'category': category,
      'note': note,
      'googleCalendarEventId': googleCalendarEventId,
      'lastModified': lastModified != null 
          ? Timestamp.fromDate(lastModified!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
