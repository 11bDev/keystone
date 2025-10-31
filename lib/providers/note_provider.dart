import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/note.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/providers/sync_provider.dart';
import 'package:keystone/providers/firestore_sync_provider.dart';

final noteListProvider = StateNotifierProvider<NoteListNotifier, List<Note>>((
  ref,
) {
  return NoteListNotifier(ref);
});

class NoteListNotifier extends StateNotifier<List<Note>> {
  final Box<Note> _box = Hive.box<Note>('notes');
  final Ref _ref;

  NoteListNotifier(this._ref) : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final notes = _box.values.toList();
    notes.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    state = notes;
  }

  void reload() {
    _loadNotes();
  }

  Future<void> _triggerAutoSync() async {
    try {
      await _ref.read(syncNotifierProvider.notifier).changeSync();
    } catch (e) {
      // Silently fail - auto-sync is best-effort
    }
  }

  void _syncToFirestore(Note note) {
    try {
      final firestoreSyncService = _ref.read(firestoreSyncServiceProvider);
      firestoreSyncService.syncSingleNote(note);
    } catch (e) {
      // Silently fail - Firestore sync is best-effort
    }
  }

  void addNote(String content, {String? title, String? tags}) async {
    final note = Note()
      ..content = content
      ..creationDate = DateTime.now()
      ..optionalTitle = title
      ..tags = tags?.split(' ').where((t) => t.startsWith('#')).toList() ?? []
      ..lastModified = DateTime.now();

    await _box.add(note);
    state = [note, ...state];
    await _triggerAutoSync();
    _syncToFirestore(note);
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
    await note.save();
    state = [
      for (final n in state)
        if (n.key == note.key) note else n,
    ];
    await _triggerAutoSync();
    _syncToFirestore(note);
  }

  void deleteNote(Note note) async {
    await note.delete();
    state = state.where((n) => n.key != note.key).toList();
    await _triggerAutoSync();
    
    // Delete from Firestore
    if (note.firestoreId != null) {
      final firestoreSyncService = _ref.read(firestoreSyncServiceProvider);
      await firestoreSyncService.deleteNoteFromFirestore(note);
    }
  }
}
