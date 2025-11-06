import 'package:cloud_firestore/cloud_firestore.dart';

// Item for permanent lists (stored within the list document)
class PermanentListItem {
  final String text;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  PermanentListItem({
    required this.text,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory PermanentListItem.fromMap(Map<String, dynamic> map) {
    return PermanentListItem(
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  PermanentListItem copyWith({
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PermanentListItem(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class AppList {
  final String? id;
  final String title;
  final String? description;
  final bool isTemporary; // true for temporary lists, false for permanent
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<PermanentListItem> items; // For permanent lists - items with completion status
  final bool isDeleted;

  AppList({
    this.id,
    required this.title,
    this.description,
    required this.isTemporary,
    DateTime? createdAt,
    this.updatedAt,
    List<PermanentListItem>? items,
    this.isDeleted = false,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isTemporary': isTemporary,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'items': items.map((item) => item.toMap()).toList(),
      'isDeleted': isDeleted,
    };
  }

  // Create from Firestore document
  factory AppList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both old string format and new object format for backward compatibility
    List<PermanentListItem> parsedItems = [];
    if (data['items'] != null) {
      final itemsData = data['items'] as List;
      parsedItems = itemsData.map((item) {
        if (item is String) {
          // Old format - convert string to PermanentListItem
          return PermanentListItem(text: item);
        } else if (item is Map<String, dynamic>) {
          // New format
          return PermanentListItem.fromMap(item);
        }
        return PermanentListItem(text: '');
      }).toList();
    }
    
    return AppList(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      isTemporary: data['isTemporary'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      items: parsedItems,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  AppList copyWith({
    String? id,
    String? title,
    String? description,
    bool? isTemporary,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PermanentListItem>? items,
    bool? isDeleted,
  }) {
    return AppList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isTemporary: isTemporary ?? this.isTemporary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ListItem {
  final String? id;
  final String listId; // Reference to the AppList
  final String text;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isDeleted;

  ListItem({
    this.id,
    required this.listId,
    required this.text,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'text': text,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isDeleted': isDeleted,
    };
  }

  // Create from Firestore document
  factory ListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListItem(
      id: doc.id,
      listId: data['listId'] ?? '',
      text: data['text'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  ListItem copyWith({
    String? id,
    String? listId,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isDeleted,
  }) {
    return ListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
