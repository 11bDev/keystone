import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;

  late String text;

  String status = 'pending'; // e.g., 'pending', 'done', 'migrated', 'canceled'

  late DateTime dueDate;

  List<String> tags = [];

  String category = 'task'; // e.g., 'task', 'event'

  String? note; // Optional short note for additional context

  String? googleCalendarEventId; // Google Calendar event ID if synced

  DateTime? lastModified; // Local timestamp for conflict resolution

  // Event time fields (only used when category is 'event')
  DateTime? eventStartTime; // Start time for events (includes date and time)

  DateTime? eventEndTime; // End time for events (includes date and time)

  /// Create Task from Firestore document
  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final task = Task();
    task.id = doc.id;
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
    task.eventStartTime = data['eventStartTime'] != null
        ? (data['eventStartTime'] as Timestamp).toDate()
        : null;
    task.eventEndTime = data['eventEndTime'] != null
        ? (data['eventEndTime'] as Timestamp).toDate()
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
      'eventStartTime': eventStartTime != null
          ? Timestamp.fromDate(eventStartTime!)
          : null,
      'eventEndTime': eventEndTime != null
          ? Timestamp.fromDate(eventEndTime!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
