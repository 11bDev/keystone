import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final noteListProvider =
    StateNotifierProvider<NoteListNotifier, List<Note>>((ref) {
  return NoteListNotifier(ref);
});

class NoteListNotifier extends StateNotifier<List<Note>> {
  final Ref _ref;
  final CollectionReference<Note> _notesCollection;

  NoteListNotifier(this._ref)
      : _notesCollection =
            FirebaseFirestore.instance.collection('notes').withConverter<Note>(
                  fromFirestore: (snapshot, _) => Note.fromFirestore(snapshot),
                  toFirestore: (note, _) => note.toFirestore(),
                ),
        super([]) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final snapshot =
        await _notesCollection.orderBy('creationDate', descending: true).get();
    state = snapshot.docs.map((doc) => doc.data()).toList();
  }

  void reload() {
    _loadNotes();
  }

  void addNote(String content, {String? title, String? tags}) async {
    final note = Note()
      ..content = content
      ..creationDate = DateTime.now()
      ..optionalTitle = title
      ..tags = tags?.split(' ').where((t) => t.startsWith('#')).toList() ?? []
      ..lastModified = DateTime.now();

    final docRef = await _notesCollection.add(note);
    note.id = docRef.id;
    
    state = [note, ...state];
  }

  void updateNote(
    Note note,
    String newContent, {
    String? newTitle,
    String? newTags,
  }) async {
    note.content = newContent;
    note.optionalTitle = newTitle;
    note.tags =
        newTags?.split(' ').where((t) => t.startsWith('#')).toList() ?? [];
    note.lastModified = DateTime.now();
    
    if (note.id != null) {
      await _notesCollection.doc(note.id).set(note);
    }
    
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
  }

  void deleteNote(Note note) async {
    if (note.id != null) {
      await _notesCollection.doc(note.id).delete();
    }
    
    state = state.where((n) => n.id != note.id).toList();
  }
}
