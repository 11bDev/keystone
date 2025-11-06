import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final journalEntryListProvider =
    StateNotifierProvider<JournalEntryListNotifier, List<JournalEntry>>((ref) {
  return JournalEntryListNotifier(ref);
});

class JournalEntryListNotifier extends StateNotifier<List<JournalEntry>> {
  final Ref _ref;
  final CollectionReference<JournalEntry> _journalEntriesCollection;

  JournalEntryListNotifier(this._ref)
      : _journalEntriesCollection = FirebaseFirestore.instance
            .collection('journal_entries')
            .withConverter<JournalEntry>(
              fromFirestore: (snapshot, _) =>
                  JournalEntry.fromFirestore(snapshot),
              toFirestore: (entry, _) => entry.toFirestore(),
            ),
        super([]) {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final snapshot = await _journalEntriesCollection
        .orderBy('creationDate', descending: true)
        .get();
    state = snapshot.docs.map((doc) => doc.data()).toList();
  }

  void reload() {
    _loadEntries();
  }

  void addJournalEntry(
    String body, {
    List<String>? imagePaths,
    String? tags,
  }) async {
    final entry = JournalEntry()
      ..body = body
      ..creationDate = DateTime.now()
      ..imagePaths = imagePaths ?? []
      ..tags = tags?.split(' ').where((t) => t.startsWith('#')).toList() ?? []
      ..lastModified = DateTime.now();

    final docRef = await _journalEntriesCollection.add(entry);
    entry.id = docRef.id;
    
    state = [entry, ...state];
  }

  void updateJournalEntry(
    JournalEntry entry,
    String newBody, {
    String? newTags,
  }) async {
    entry.body = newBody;
    entry.tags =
        newTags?.split(' ').where((t) => t.startsWith('#')).toList() ?? [];
    entry.lastModified = DateTime.now();
    
    if (entry.id != null) {
      await _journalEntriesCollection.doc(entry.id).set(entry);
    }
    
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ];
  }

  void addImageToJournalEntry(JournalEntry entry, String imagePath) async {
    entry.imagePaths.add(imagePath);
    entry.lastModified = DateTime.now();
    
    if (entry.id != null) {
      await _journalEntriesCollection.doc(entry.id).set(entry);
    }
    
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ];
  }

  void deleteJournalEntry(JournalEntry entry) async {
    if (entry.id != null) {
      await _journalEntriesCollection.doc(entry.id).delete();
    }
    
    state = state.where((e) => e.id != entry.id).toList();
  }
}
