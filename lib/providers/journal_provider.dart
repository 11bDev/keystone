import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Stream provider for journal entries
final journalEntryListProvider = StreamProvider<List<JournalEntry>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal_entries')
          .orderBy('creationDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Service class for journal operations
class JournalService {
  final FirebaseFirestore _firestore;
  final String _userId;

  JournalService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>> get _journalEntriesCollection =>
      _firestore.collection('users').doc(_userId).collection('journal_entries');

  Future<void> addJournalEntry(
    String body, {
    List<String>? imagePaths,
    String? tags,
  }) async {
    final entry = JournalEntry()
      ..body = body
      ..creationDate = DateTime.now()
      ..imagePaths = imagePaths ?? []
      ..tags = tags?.split(' ').where((t) => t.startsWith('#') || t.startsWith('-')).toList() ?? []
      ..lastModified = DateTime.now();

    await _journalEntriesCollection.add(entry.toFirestore());
  }

  Future<void> updateJournalEntry(
    String entryId,
    String newBody, {
    String? newTags,
  }) async {
    await _journalEntriesCollection.doc(entryId).update({
      'body': newBody,
      'tags': newTags?.split(' ').where((t) => t.startsWith('#') || t.startsWith('-')).toList() ?? [],
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addImageToJournalEntry(String entryId, String imagePath) async {
    await _journalEntriesCollection.doc(entryId).update({
      'imagePaths': FieldValue.arrayUnion([imagePath]),
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJournalEntry(String entryId) async {
    await _journalEntriesCollection.doc(entryId).delete();
  }
}

// Provider for journal service
final journalServiceProvider = Provider<JournalService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) => user != null ? JournalService(firestore, user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
