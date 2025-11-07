import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/note.dart';
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

// Stream provider for notes
final noteListProvider = StreamProvider<List<Note>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .orderBy('creationDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Note.fromFirestore(doc))
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Service class for note operations
class NoteService {
  final FirebaseFirestore _firestore;
  final String _userId;

  NoteService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('users').doc(_userId).collection('notes');

  Future<void> addNote(String content, {String? title, String? tags}) async {
    final note = Note()
      ..content = content
      ..creationDate = DateTime.now()
      ..optionalTitle = title
      ..tags = tags?.split(' ').where((t) => t.startsWith('#') || t.startsWith('@')).toList() ?? []
      ..lastModified = DateTime.now();

    await _notesCollection.add(note.toFirestore());
  }

  Future<void> updateNote(
    String noteId,
    String newContent, {
    String? newTitle,
    String? newTags,
  }) async {
    await _notesCollection.doc(noteId).update({
      'content': newContent,
      'optionalTitle': newTitle,
      'tags': newTags?.split(' ').where((t) => t.startsWith('#') || t.startsWith('@')).toList() ?? [],
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }
}

// Provider for note service
final noteServiceProvider = Provider<NoteService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) => user != null ? NoteService(firestore, user.uid) : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
