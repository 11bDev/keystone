import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple project model for demonstrating Firestore offline-first sync
class Project {
  final String id;
  final String name;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Project.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(
      id: doc.id,
      name: data['name'] as String,
      isCompleted: data['isCompleted'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  Project copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, isCompleted: $isCompleted)';
  }
}
