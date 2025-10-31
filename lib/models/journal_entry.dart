import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String body;

  @HiveField(1)
  late DateTime creationDate;

  @HiveField(2)
  List<String> imagePaths = [];

  @HiveField(3)
  List<String> tags = [];

  @HiveField(4)
  DateTime? lastModified; // Local timestamp for conflict resolution

  // Firestore sync support
  String? firestoreId; // Firestore document ID for syncing

  /// Create JournalEntry from Firestore document
  static JournalEntry fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final entry = JournalEntry();
    entry.firestoreId = doc.id;
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
