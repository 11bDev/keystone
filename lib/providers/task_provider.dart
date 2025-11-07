import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keystone/services/google_calendar_service.dart';
import 'package:keystone/providers/settings_provider.dart';
import 'package:keystone/providers/auth_provider.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Stream provider for tasks
final taskListProvider = StreamProvider<List<Task>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Service class for task operations
class TaskService {
  final FirebaseFirestore _firestore;
  final String _userId;
  final GoogleCalendarService? _calendarService;
  final bool _syncEnabled;

  TaskService(
    this._firestore,
    this._userId, {
    GoogleCalendarService? calendarService,
    bool syncEnabled = false,
  })  : _calendarService = calendarService,
        _syncEnabled = syncEnabled;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(_userId).collection('tasks');

  Future<void> addTask(
    String text, {
    String? tags,
    DateTime? dueDate,
    String category = 'task',
    String? note,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
  }) async {
    final task = Task()
      ..text = text
      ..dueDate = dueDate ?? DateTime.now()
      ..tags = tags?.split(' ').where((t) => t.startsWith('#') || t.startsWith('@')).toList() ?? []
      ..category = category
      ..note = note
      ..status = 'pending'
      ..eventStartTime = eventStartTime
      ..eventEndTime = eventEndTime
      ..lastModified = DateTime.now();

    // Add to Firestore
    final docRef = await _tasksCollection.add(task.toFirestore());
    task.id = docRef.id;

    // Sync to Google Calendar if enabled and it's an event
    if (_syncEnabled &&
        category == 'event' &&
        _calendarService != null &&
        _calendarService!.isInitialized) {
      final eventId = await _calendarService!.addEventToCalendar(task);
      if (eventId != null) {
        // Update task with Google Calendar event ID
        await _tasksCollection.doc(docRef.id).update({
          'googleCalendarEventId': eventId,
        });
      }
    }
  }

  Future<void> addTaskObject(Task task) async {
    task.lastModified = DateTime.now();
    await _tasksCollection.add(task.toFirestore());
  }

  Future<void> toggleTaskStatus(String taskId, String currentStatus) async {
    final newStatus = currentStatus == 'pending' ? 'done' : 'pending';
    await _tasksCollection.doc(taskId).update({
      'status': newStatus,
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(
    String taskId,
    String newText,
    String newTags, {
    DateTime? dueDate,
    String? category,
    String? note,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
  }) async {
    final updateData = <String, dynamic>{
      'text': newText,
      'tags': newTags.split(' ').where((t) => t.startsWith('#') || t.startsWith('@')).toList(),
      'lastModified': FieldValue.serverTimestamp(),
    };
    
    if (dueDate != null) {
      updateData['dueDate'] = Timestamp.fromDate(dueDate);
    }
    if (category != null) {
      updateData['category'] = category;
    }
    if (note != null) {
      updateData['note'] = note;
    }
    if (eventStartTime != null) {
      updateData['eventStartTime'] = Timestamp.fromDate(eventStartTime);
    } else {
      updateData['eventStartTime'] = null;
    }
    if (eventEndTime != null) {
      updateData['eventEndTime'] = Timestamp.fromDate(eventEndTime);
    } else {
      updateData['eventEndTime'] = null;
    }

    await _tasksCollection.doc(taskId).update(updateData);

    // Sync to Google Calendar if enabled and it's an event
    if (_syncEnabled &&
        category == 'event' &&
        _calendarService != null &&
        _calendarService!.isInitialized) {
      // Get the task to check if it already has a calendar event
      final taskDoc = await _tasksCollection.doc(taskId).get();
      if (taskDoc.exists) {
        final task = Task.fromFirestore(taskDoc);
        
        if (task.googleCalendarEventId != null) {
          // Update existing event
          await _calendarService!.updateEventInCalendar(
            task.googleCalendarEventId!,
            task,
          );
        } else {
          // Create new event
          final eventId = await _calendarService!.addEventToCalendar(task);
          if (eventId != null) {
            await _tasksCollection.doc(taskId).update({
              'googleCalendarEventId': eventId,
            });
          }
        }
      }
    }
  }

  Future<void> migrateTask(String taskId, DateTime newDueDate) async {
    // Get the original task
    final taskDoc = await _tasksCollection.doc(taskId).get();
    if (!taskDoc.exists) return;
    
    final taskData = taskDoc.data()!;
    
    // Create a new task for the new date
    final newTask = Task()
      ..text = taskData['text'] as String
      ..dueDate = newDueDate
      ..tags = List<String>.from(taskData['tags'] as List? ?? [])
      ..category = taskData['category'] as String? ?? 'task'
      ..note = taskData['note'] as String?
      ..status = 'pending'
      ..lastModified = DateTime.now();

    // Update the original task's status to 'migrated'
    await _tasksCollection.doc(taskId).update({
      'status': 'migrated',
      'lastModified': FieldValue.serverTimestamp(),
    });
    
    // Add the new task
    await _tasksCollection.add(newTask.toFirestore());
  }

  Future<void> cancelTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'status': 'canceled',
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uncancelTask(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'status': 'pending',
      'lastModified': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    // Get the task first to check for Google Calendar event
    if (_syncEnabled && _calendarService != null && _calendarService!.isInitialized) {
      final taskDoc = await _tasksCollection.doc(taskId).get();
      if (taskDoc.exists) {
        final task = Task.fromFirestore(taskDoc);
        if (task.googleCalendarEventId != null) {
          await _calendarService!.deleteEventFromCalendar(task.googleCalendarEventId!);
        }
      }
    }
    
    await _tasksCollection.doc(taskId).delete();
  }
}

// Provider for task service
final taskServiceProvider = Provider<TaskService?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userAsync = ref.watch(currentUserProvider);
  final calendarService = ref.watch(googleCalendarServiceProvider);
  final syncEnabled = ref.watch(googleCalendarSyncProvider);
  
  return userAsync.when(
    data: (user) => user != null
        ? TaskService(
            firestore,
            user.uid,
            calendarService: calendarService,
            syncEnabled: syncEnabled,
          )
        : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
