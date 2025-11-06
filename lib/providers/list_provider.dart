import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keystone/models/list.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider for all lists
final listsProvider = StreamProvider<List<AppList>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppList.fromFirestore(doc))
              .where((list) => !list.isDeleted) // Filter in memory instead
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for list items by list ID
final listItemsProvider = StreamProvider.family<List<ListItem>, String>((ref, listId) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('listItems')
          .where('listId', isEqualTo: listId)
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs
                .map((doc) => ListItem.fromFirestore(doc))
                .where((item) => !item.isDeleted)
                .toList();
            
            // Sort by createdAt in memory to avoid needing a composite index
            items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return items;
          });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for a single list by ID
final singleListProvider = StreamProvider.family<AppList?, String>((ref, listId) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return AppList.fromFirestore(doc);
          });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Service class for list operations
class ListService {
  final FirebaseFirestore _firestore;
  final String _userId;

  ListService(this._firestore, this._userId);

  // Add a new list
  Future<void> addList(AppList list) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lists')
        .add(list.toFirestore());
  }

  // Update an existing list
  Future<void> updateList(AppList list) async {
    if (list.id == null) return;
    
    final updatedList = list.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lists')
        .doc(list.id)
        .update(updatedList.toFirestore());
  }

  // Delete a list (soft delete)
  Future<void> deleteList(String listId) async {
    // Mark list as deleted
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lists')
        .doc(listId)
        .update({'isDeleted': true});
    
    // Mark all items in the list as deleted
    final itemsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('listItems')
        .where('listId', isEqualTo: listId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in itemsSnapshot.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }
    await batch.commit();
  }

  // Add item to temporary list
  Future<void> addListItem(ListItem item) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('listItems')
        .add(item.toFirestore());
  }

  // Toggle item completion
  Future<void> toggleListItem(String itemId, bool currentState) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('listItems')
        .doc(itemId)
        .update({
      'isCompleted': !currentState,
      'completedAt': !currentState ? Timestamp.now() : null,
    });
  }

  // Delete a list item
  Future<void> deleteListItem(String itemId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('listItems')
        .doc(itemId)
        .update({'isDeleted': true});
  }

  // Delete all completed items in a list
  Future<void> deleteCompletedItems(String listId) async {
    final completedItems = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('listItems')
        .where('listId', isEqualTo: listId)
        .where('isCompleted', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in completedItems.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }
    await batch.commit();
  }
}

// Provider for list service
final listServiceProvider = Provider<ListService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) => user != null ? ListService(firestore, user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
