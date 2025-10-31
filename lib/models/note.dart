import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  late String content;

  @HiveField(1)
  late DateTime creationDate;

  @HiveField(2)
  String? optionalTitle;

  @HiveField(3)
  List<String> tags = [];

  @HiveField(4)
  DateTime? lastModified; // Local timestamp for conflict resolution

  // Firestore sync support
  String? firestoreId; // Firestore document ID for syncing

  /// Create Note from Firestore document
  static Note fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final note = Note();
    note.firestoreId = doc.id;
    note.content = data['content'] as String;
    note.creationDate = (data['creationDate'] as Timestamp).toDate();
    note.optionalTitle = data['optionalTitle'] as String?;
    note.tags = List<String>.from(data['tags'] as List? ?? []);
    note.lastModified = data['lastModified'] != null 
        ? (data['lastModified'] as Timestamp).toDate()
        : null;
    return note;
  }

  /// Convert Note to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'creationDate': Timestamp.fromDate(creationDate),
      'optionalTitle': optionalTitle,
      'tags': tags,
      'lastModified': lastModified != null 
          ? Timestamp.fromDate(lastModified!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
