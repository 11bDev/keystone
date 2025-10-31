import 'package:hive/hive.dart';
import 'firestore_service.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/journal_entry.dart';

/// Service to sync Hive data to Firestore
///
/// This service handles bidirectional sync between local Hive storage
/// and cloud Firestore storage, maintaining Hive as the primary source
/// of truth for the UI.
class FirestoreSyncService {
  final FirestoreService _firestoreService;

  FirestoreSyncService(this._firestoreService);

  /// Sync a single task to Firestore
  Future<void> syncSingleTask(Task task) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (task.firestoreId == null) {
        // New task - add to Firestore
        final firestoreId = await _firestoreService.addTask(task);
        task.firestoreId = firestoreId;
        await task.save();
      } else {
        // Existing task - update in Firestore
        await _firestoreService.updateTask(task.firestoreId!, task);
      }
    } catch (e) {
      print('❌ Error syncing task: $e');
    }
  }

  /// Sync a single note to Firestore
  Future<void> syncSingleNote(Note note) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (note.firestoreId == null) {
        // New note - add to Firestore
        final firestoreId = await _firestoreService.addNote(note);
        note.firestoreId = firestoreId;
        await note.save();
      } else {
        // Existing note - update in Firestore
        await _firestoreService.updateNote(note.firestoreId!, note);
      }
    } catch (e) {
      print('❌ Error syncing note: $e');
    }
  }

  /// Sync a single journal entry to Firestore
  Future<void> syncSingleJournalEntry(JournalEntry entry) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      if (entry.firestoreId == null) {
        // New entry - add to Firestore
        final firestoreId = await _firestoreService.addJournalEntry(entry);
        entry.firestoreId = firestoreId;
        await entry.save();
      } else {
        // Existing entry - update in Firestore
        await _firestoreService.updateJournalEntry(entry.firestoreId!, entry);
      }
    } catch (e) {
      print('❌ Error syncing journal entry: $e');
    }
  }

  /// Delete a task from Firestore
  Future<void> deleteTaskFromFirestore(Task task) async {
    if (!_firestoreService.isSignedIn || task.firestoreId == null) return;

    try {
      await _firestoreService.deleteTask(task.firestoreId!);
    } catch (e) {
      print('❌ Error deleting task from Firestore: $e');
    }
  }

  /// Delete a note from Firestore
  Future<void> deleteNoteFromFirestore(Note note) async {
    if (!_firestoreService.isSignedIn || note.firestoreId == null) return;

    try {
      await _firestoreService.deleteNote(note.firestoreId!);
    } catch (e) {
      print('❌ Error deleting note from Firestore: $e');
    }
  }

  /// Delete a journal entry from Firestore
  Future<void> deleteJournalEntryFromFirestore(JournalEntry entry) async {
    if (!_firestoreService.isSignedIn || entry.firestoreId == null) return;

    try {
      await _firestoreService.deleteJournalEntry(entry.firestoreId!);
    } catch (e) {
      print('❌ Error deleting journal entry from Firestore: $e');
    }
  }

  /// Sync all tasks from Hive to Firestore
  Future<void> syncTasksToFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final tasksBox = await Hive.openBox<Task>('tasks');

      for (var task in tasksBox.values) {
        if (task.firestoreId == null) {
          // New task - add to Firestore
          final firestoreId = await _firestoreService.addTask(task);
          task.firestoreId = firestoreId;
          await task.save(); // Update Hive with Firestore ID
        } else {
          // Existing task - update in Firestore
          try {
            await _firestoreService.updateTask(task.firestoreId!, task);
          } catch (e) {
            // If document doesn't exist, add it
            final firestoreId = await _firestoreService.addTask(task);
            task.firestoreId = firestoreId;
            await task.save();
          }
        }
      }

      print('✅ Synced ${tasksBox.length} tasks to Firestore');
    } catch (e) {
      print('❌ Error syncing tasks: $e');
    }
  }

  /// Sync all notes from Hive to Firestore
  Future<void> syncNotesToFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final notesBox = await Hive.openBox<Note>('notes');

      for (var note in notesBox.values) {
        if (note.firestoreId == null) {
          // New note - add to Firestore
          final firestoreId = await _firestoreService.addNote(note);
          note.firestoreId = firestoreId;
          await note.save(); // Update Hive with Firestore ID
        } else {
          // Existing note - update in Firestore
          try {
            await _firestoreService.updateNote(note.firestoreId!, note);
          } catch (e) {
            // If document doesn't exist, add it
            final firestoreId = await _firestoreService.addNote(note);
            note.firestoreId = firestoreId;
            await note.save();
          }
        }
      }

      print('✅ Synced ${notesBox.length} notes to Firestore');
    } catch (e) {
      print('❌ Error syncing notes: $e');
    }
  }

  /// Sync all journal entries from Hive to Firestore
  Future<void> syncJournalEntriesToFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final journalBox = await Hive.openBox<JournalEntry>('journal_entries');

      for (var entry in journalBox.values) {
        if (entry.firestoreId == null) {
          // New entry - add to Firestore
          final firestoreId = await _firestoreService.addJournalEntry(entry);
          entry.firestoreId = firestoreId;
          await entry.save(); // Update Hive with Firestore ID
        } else {
          // Existing entry - update in Firestore
          try {
            await _firestoreService.updateJournalEntry(
              entry.firestoreId!,
              entry,
            );
          } catch (e) {
            // If document doesn't exist, add it
            final firestoreId = await _firestoreService.addJournalEntry(entry);
            entry.firestoreId = firestoreId;
            await entry.save();
          }
        }
      }

      print('✅ Synced ${journalBox.length} journal entries to Firestore');
    } catch (e) {
      print('❌ Error syncing journal entries: $e');
    }
  }

  /// Sync all data from Hive to Firestore
  Future<void> syncAllToFirestore() async {
    await syncTasksToFirestore();
    await syncNotesToFirestore();
    await syncJournalEntriesToFirestore();
  }

  /// Pull tasks from Firestore to Hive
  Future<void> pullTasksFromFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final tasksBox = await Hive.openBox<Task>('tasks');

      // Get all tasks from Firestore once
      final snapshot = await _firestoreService.tasksCollection!.get();

      for (var doc in snapshot.docs) {
        final firestoreTask = Task.fromFirestore(doc);

        // Find if this task already exists in Hive
        final existingTask = tasksBox.values.firstWhere(
          (t) => t.firestoreId == doc.id,
          orElse: () => Task(),
        );

        if (existingTask.isInBox) {
          // Conflict resolution: only update if cloud version is newer
          final localModified = existingTask.lastModified;
          final cloudModified = firestoreTask.lastModified;
          
          if (cloudModified != null && 
              (localModified == null || cloudModified.isAfter(localModified))) {
            // Cloud version is newer - update local
            print('📥 Updating task "${existingTask.text}" (cloud newer)');
            existingTask.text = firestoreTask.text;
            existingTask.status = firestoreTask.status;
            existingTask.dueDate = firestoreTask.dueDate;
            existingTask.tags = firestoreTask.tags;
            existingTask.category = firestoreTask.category;
            existingTask.note = firestoreTask.note;
            existingTask.googleCalendarEventId =
                firestoreTask.googleCalendarEventId;
            existingTask.lastModified = firestoreTask.lastModified;
            await existingTask.save();
          } else {
            // Local version is newer or same - skip update
            print('⏭️  Skipping task "${existingTask.text}" (local newer/same)');
          }
        } else {
          // Add new task
          await tasksBox.add(firestoreTask);
        }
      }

      print('✅ Pulled ${snapshot.docs.length} tasks from Firestore');
    } catch (e) {
      print('❌ Error pulling tasks: $e');
    }
  }

  /// Pull all data from Firestore to Hive (for initial sync or restore)
  Future<void> pullAllFromFirestore() async {
    await pullTasksFromFirestore();
    await pullNotesFromFirestore();
    await pullJournalEntriesFromFirestore();
  }

  /// Pull notes from Firestore to Hive
  Future<void> pullNotesFromFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final notesBox = await Hive.openBox<Note>('notes');

      // Get all notes from Firestore
      final snapshot = await _firestoreService.notesCollection!.get();

      for (var doc in snapshot.docs) {
        final firestoreNote = Note.fromFirestore(doc);

        // Find if this note already exists in Hive
        final existingNote = notesBox.values.firstWhere(
          (n) => n.firestoreId == doc.id,
          orElse: () => Note(),
        );

        if (existingNote.isInBox) {
          // Conflict resolution: only update if cloud version is newer
          final localModified = existingNote.lastModified;
          final cloudModified = firestoreNote.lastModified;
          
          if (cloudModified != null && 
              (localModified == null || cloudModified.isAfter(localModified))) {
            // Cloud version is newer - update local
            print('📥 Updating note (cloud newer)');
            existingNote.optionalTitle = firestoreNote.optionalTitle;
            existingNote.content = firestoreNote.content;
            existingNote.creationDate = firestoreNote.creationDate;
            existingNote.tags = firestoreNote.tags;
            existingNote.lastModified = firestoreNote.lastModified;
            await existingNote.save();
          } else {
            // Local version is newer or same - skip update
            print('⏭️  Skipping note (local newer/same)');
          }
        } else {
          // Add new note
          await notesBox.add(firestoreNote);
        }
      }

      print('✅ Pulled ${snapshot.docs.length} notes from Firestore');
    } catch (e) {
      print('❌ Error pulling notes: $e');
    }
  }

  /// Pull journal entries from Firestore to Hive
  Future<void> pullJournalEntriesFromFirestore() async {
    if (!_firestoreService.isSignedIn) return;

    try {
      final journalBox = await Hive.openBox<JournalEntry>('journal_entries');

      // Get all journal entries from Firestore
      final snapshot = await _firestoreService.journalEntriesCollection!.get();

      for (var doc in snapshot.docs) {
        final firestoreEntry = JournalEntry.fromFirestore(doc);

        // Find if this entry already exists in Hive
        final existingEntry = journalBox.values.firstWhere(
          (e) => e.firestoreId == doc.id,
          orElse: () => JournalEntry(),
        );

        if (existingEntry.isInBox) {
          // Conflict resolution: only update if cloud version is newer
          final localModified = existingEntry.lastModified;
          final cloudModified = firestoreEntry.lastModified;
          
          if (cloudModified != null && 
              (localModified == null || cloudModified.isAfter(localModified))) {
            // Cloud version is newer - update local
            print('📥 Updating journal entry (cloud newer)');
            existingEntry.body = firestoreEntry.body;
            existingEntry.creationDate = firestoreEntry.creationDate;
            existingEntry.tags = firestoreEntry.tags;
            existingEntry.imagePaths = firestoreEntry.imagePaths;
            existingEntry.lastModified = firestoreEntry.lastModified;
            await existingEntry.save();
          } else {
            // Local version is newer or same - skip update
            print('⏭️  Skipping journal entry (local newer/same)');
          }
        } else {
          // Add new entry
          await journalBox.add(firestoreEntry);
        }
      }

      print('✅ Pulled ${snapshot.docs.length} journal entries from Firestore');
    } catch (e) {
      print('❌ Error pulling journal entries: $e');
    }
  }
}
