import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  String? id;

  late String body;

  late DateTime creationDate;

  List<String> imagePaths = [];

  List<String> tags = [];

  DateTime? lastModified; // Local timestamp for conflict resolution

  /// Create JournalEntry from Firestore document
  static JournalEntry fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final entry = JournalEntry();
    entry.id = doc.id;
    entry.body = data['body'] as String;
    entry.creationDate = (data['creationDate'] as Timestamp).toDate();
    entry.imagePaths = List<String>.from(data['imagePaths'] as List? ?? []);
    entry.tags = List<String>.from(data['tags'] as List? ?? []);
    entry.lastModified = data['lastModified'] != null 
        ? (data['lastModified'] as Timestamp).toDate()
        : null;
    return entry;
  }

  /// Convert JournalEntry to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'body': body,
      'creationDate': Timestamp.fromDate(creationDate),
      'imagePaths': imagePaths,
      'tags': tags,
      'lastModified': lastModified != null 
          ? Timestamp.fromDate(lastModified!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
