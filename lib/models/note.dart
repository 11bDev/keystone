import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String? id;

  late String content;

  late DateTime creationDate;

  String? optionalTitle;

  List<String> tags = [];

  DateTime? lastModified; // Local timestamp for conflict resolution

  /// Create Note from Firestore document
  static Note fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final note = Note();
    note.id = doc.id;
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
