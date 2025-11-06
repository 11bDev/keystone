import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/services/firestore_service.dart';

/// This service handles bidirectional sync between local Isar storage
/// and cloud Firestore storage, maintaining Isar as the primary source
/// of truth for the UI.
class FirestoreSyncService {
  final Isar isar;
  final FirestoreService _firestoreService;

  FirestoreSyncService(this.isar, this._firestoreService);

  /// Sync a single task to Firestore.
  Future<void> syncSingleTask(Task task) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (task.firestoreId == null || task.firestoreId!.isEmpty) {
        // New task - add to Firestore
        final docRef = await _firestoreService.tasksCollection
            ?.add(task.toFirestore());
        task.firestoreId = docRef?.id;
      } else {
        // Existing task - update in Firestore
        await _firestoreService.tasksCollection
            ?.doc(task.firestoreId)
            .set(task.toFirestore(), SetOptions(merge: true));
      }
      // Update the local Isar instance with the firestoreId
      await isar.writeTxn(() async => await isar.tasks.put(task));
    } catch (e) {
      print('Error syncing single task to Firestore: $e');
    }
  }

  /// Sync a single note to Firestore.
  Future<void> syncSingleNote(Note note) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (note.firestoreId == null || note.firestoreId!.isEmpty) {
        final docRef = await _firestoreService.notesCollection
            ?.add(note.toFirestore());
        note.firestoreId = docRef?.id;
      } else {
        await _firestoreService.notesCollection
            ?.doc(note.firestoreId)
            .set(note.toFirestore(), SetOptions(merge: true));
      }
      await isar.writeTxn(() async => await isar.notes.put(note));
    } catch (e) {
      print('Error syncing single note to Firestore: $e');
    }
  }

  /// Sync a single journal entry to Firestore.
  Future<void> syncSingleJournalEntry(JournalEntry entry) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (entry.firestoreId == null || entry.firestoreId!.isEmpty) {
        final docRef = await _firestoreService.journalEntriesCollection
            ?.add(entry.toFirestore());
        entry.firestoreId = docRef?.id;
      } else {
        await _firestoreService.journalEntriesCollection
            ?.doc(entry.firestoreId)
            .set(entry.toFirestore(), SetOptions(merge: true));
      }
      await isar.writeTxn(() async => await isar.journalEntrys.put(entry));
    } catch (e) {
      print('Error syncing single journal entry to Firestore: $e');
    }
  }

  /// Delete a task from Firestore.
  Future<void> deleteTaskFromFirestore(Task task) async {
    if (!_firestoreService.isSignedIn || task.firestoreId == null) return;
    try {
      await _firestoreService.tasksCollection?.doc(task.firestoreId).delete();
    } catch (e) {
      print('Error deleting task from Firestore: $e');
    }
  }

  /// Delete a note from Firestore.
  Future<void> deleteNoteFromFirestore(Note note) async {
    if (!_firestoreService.isSignedIn || note.firestoreId == null) return;
    try {
      await _firestoreService.notesCollection?.doc(note.firestoreId).delete();
    } catch (e) {
      print('Error deleting note from Firestore: $e');
    }
  }

  /// Delete a journal entry from Firestore.
  Future<void> deleteJournalEntryFromFirestore(JournalEntry entry) async {
    if (!_firestoreService.isSignedIn || entry.firestoreId == null) return;
    try {
      await _firestoreService.journalEntriesCollection
          ?.doc(entry.firestoreId)
          .delete();
    } catch (e) {
      print('Error deleting journal entry from Firestore: $e');
    }
  }

  /// Uploads all local data to Firestore.
  Future<void> syncAllToFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    final tasks = await isar.tasks.where().findAll();
    for (final task in tasks) {
      await syncSingleTask(task);
    }

    final notes = await isar.notes.where().findAll();
    for (final note in notes) {
      await syncSingleNote(note);
    }

    final journalEntries = await isar.journalEntrys.where().findAll();
    for (final entry in journalEntries) {
      await syncSingleJournalEntry(entry);
    }
  }

  /// Downloads all data from Firestore and merges it with local data.
  Future<void> pullAllFromFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    await _pullTasks();
    await _pullNotes();
    await _pullJournalEntries();
  }

  Future<void> _pullTasks() async {
    final snapshot = await _firestoreService.tasksCollection?.get();
    if (snapshot == null) return;
    await isar.writeTxn(() async {
      for (final doc in snapshot.docs) {
        final firestoreTask = Task.fromFirestore(doc);
        final existingTask = await isar.tasks
            .filter()
            .firestoreIdEqualTo(doc.id)
            .findFirst();

        if (existingTask != null) {
          // Conflict resolution: cloud is master for pull
          final localModified = existingTask.lastModified ?? DateTime(1970);
          final cloudModified = firestoreTask.lastModified ?? DateTime(1970);
          if (cloudModified.isAfter(localModified)) {
            firestoreTask.id = existingTask.id; // Preserve Isar ID
            await isar.tasks.put(firestoreTask);
          }
        } else {
          await isar.tasks.put(firestoreTask);
        }
      }
    });
  }

  Future<void> _pullNotes() async {
    final snapshot = await _firestoreService.notesCollection?.get();
    if (snapshot == null) return;
    await isar.writeTxn(() async {
      for (final doc in snapshot.docs) {
        final firestoreNote = Note.fromFirestore(doc);
        final existingNote = await isar.notes
            .filter()
            .firestoreIdEqualTo(doc.id)
            .findFirst();

        if (existingNote != null) {
          final localModified = existingNote.lastModified ?? DateTime(1970);
          final cloudModified = firestoreNote.lastModified ?? DateTime(1970);
          if (cloudModified.isAfter(localModified)) {
            firestoreNote.id = existingNote.id;
            await isar.notes.put(firestoreNote);
          }
        } else {
          await isar.notes.put(firestoreNote);
        }
      }
    });
  }

  Future<void> _pullJournalEntries() async {
    final snapshot =
        await _firestoreService.journalEntriesCollection?.get();
    if (snapshot == null) return;
    await isar.writeTxn(() async {
      for (final doc in snapshot.docs) {
        final firestoreEntry = JournalEntry.fromFirestore(doc);
        final existingEntry = await isar.journalEntrys
            .filter()
            .firestoreIdEqualTo(doc.id)
            .findFirst();

        if (existingEntry != null) {
          final localModified = existingEntry.lastModified ?? DateTime(1970);
          final cloudModified = firestoreEntry.lastModified ?? DateTime(1970);
          if (cloudModified.isAfter(localModified)) {
            firestoreEntry.id = existingEntry.id;
            await isar.journalEntrys.put(firestoreEntry);
          }
        } else {
          await isar.journalEntrys.put(firestoreEntry);
        }
      }
    });
  }
}
