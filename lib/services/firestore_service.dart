import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/journal_entry.dart';

/// Firestore service for offline-first data synchronization
///
/// This service demonstrates:
/// - Automatic offline persistence via Firestore cache
/// - Real-time streams for reactive UI updates
/// - User-scoped data (each user sees only their data)
/// - Optimistic updates (writes work offline, sync when online)
class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID (required for all operations)
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user is signed in
  bool get isSignedIn => _userId != null;

  /// Get reference to user's projects collection
  CollectionReference<Map<String, dynamic>>? get _projectsCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('projects');
  }

  // ==================== PROJECTS ====================

  /// Stream all projects for current user
  ///
  /// Returns real-time updates as projects are added/updated/deleted.
  /// Works offline - returns cached data when no internet connection.
  Stream<List<Project>> streamProjects() {
    if (!isSignedIn) {
      return Stream.value([]); // Empty stream if not signed in
    }

    return _projectsCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList();
        });
  }

  /// Add a new project
  ///
  /// Works offline - will sync to server when connection is restored.
  Future<void> addProject(String name) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to add projects');
    }

    final now = DateTime.now();
    final project = Project(
      id: '', // Firestore will generate ID
      name: name,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _projectsCollection!.add(project.toFirestore());
  }

  /// Update an existing project
  ///
  /// Works offline - will sync to server when connection is restored.
  Future<void> updateProject(
    String projectId, {
    String? name,
    bool? isCompleted,
  }) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to update projects');
    }

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (name != null) updates['name'] = name;
    if (isCompleted != null) updates['isCompleted'] = isCompleted;

    await _projectsCollection!.doc(projectId).update(updates);
  }

  /// Delete a project
  ///
  /// Works offline - will sync to server when connection is restored.
  Future<void> deleteProject(String projectId) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to delete projects');
    }

    await _projectsCollection!.doc(projectId).delete();
  }

  /// Toggle project completion status
  Future<void> toggleProjectCompletion(
    String projectId,
    bool currentStatus,
  ) async {
    await updateProject(projectId, isCompleted: !currentStatus);
  }

  // ==================== AUTHENTICATION ====================

  /// Sign in with Google (uses Firebase Auth)
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      // The GoogleSignIn() will automatically use the OAuth client from google-services.json
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Sign-in canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Stream of auth state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // ==================== TASKS ====================

  /// Get reference to user's tasks collection
  CollectionReference<Map<String, dynamic>>? get tasksCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  /// Stream all tasks for current user
  Stream<List<Task>> streamTasks() {
    if (!isSignedIn) {
      return Stream.value([]);
    }

    return tasksCollection!
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
        });
  }

  /// Add new task to Firestore
  Future<String> addTask(Task task) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to add tasks');
    }

    final docRef = await tasksCollection!.add(task.toFirestore());
    return docRef.id;
  }

  /// Update existing task
  Future<void> updateTask(String taskId, Task task) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to update tasks');
    }

    await tasksCollection!.doc(taskId).update(task.toFirestore());
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to delete tasks');
    }

    await tasksCollection!.doc(taskId).delete();
  }

  // ==================== NOTES ====================

  /// Get reference to user's notes collection
  CollectionReference<Map<String, dynamic>>? get notesCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('notes');
  }

  /// Stream all notes for current user
  Stream<List<Note>> streamNotes() {
    if (!isSignedIn) {
      return Stream.value([]);
    }

    return notesCollection!
        .orderBy('creationDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
        });
  }

  /// Add new note to Firestore
  Future<String> addNote(Note note) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to add notes');
    }

    final docRef = await notesCollection!.add(note.toFirestore());
    return docRef.id;
  }

  /// Update existing note
  Future<void> updateNote(String noteId, Note note) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to update notes');
    }

    await notesCollection!.doc(noteId).update(note.toFirestore());
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to delete notes');
    }

    await notesCollection!.doc(noteId).delete();
  }

  // ==================== JOURNAL ENTRIES ====================

  /// Get reference to user's journal entries collection
  CollectionReference<Map<String, dynamic>>? get journalEntriesCollection {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('journalEntries');
  }

  /// Stream all journal entries for current user
  Stream<List<JournalEntry>> streamJournalEntries() {
    if (!isSignedIn) {
      return Stream.value([]);
    }

    return journalEntriesCollection!
        .orderBy('creationDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Add new journal entry to Firestore
  Future<String> addJournalEntry(JournalEntry entry) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to add journal entries');
    }

    final docRef = await journalEntriesCollection!.add(entry.toFirestore());
    return docRef.id;
  }

  /// Update existing journal entry
  Future<void> updateJournalEntry(String entryId, JournalEntry entry) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to update journal entries');
    }

    await journalEntriesCollection!.doc(entryId).update(entry.toFirestore());
  }

  /// Delete journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    if (!isSignedIn) {
      throw Exception('User must be signed in to delete journal entries');
    }

    await journalEntriesCollection!.doc(entryId).delete();
  }

  // ==================== DIAGNOSTICS ====================

  /// Check if Firestore is using cached data (offline)
  ///
  /// Note: Firestore handles offline/online transitions automatically.
  /// This is just for debugging/UI feedback purposes.
  Future<bool> isUsingCache() async {
    try {
      // Try to fetch a document with source = server
      await _firestore
          .collection('_health')
          .doc('check')
          .get(const GetOptions(source: Source.server));
      return false; // Successfully fetched from server
    } catch (e) {
      return true; // Failed to reach server, using cache
    }
  }

  /// Enable/disable network (for testing offline mode)
  Future<void> enableNetwork(bool enable) async {
    if (enable) {
      await _firestore.enableNetwork();
    } else {
      await _firestore.disableNetwork();
    }
  }
}
