import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier(ref);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;
  final CollectionReference<Task> _tasksCollection;

  TaskListNotifier(this._ref)
      : _tasksCollection = FirebaseFirestore.instance
            .collection('tasks')
            .withConverter<Task>(
              fromFirestore: (snapshot, _) => Task.fromFirestore(snapshot),
              toFirestore: (task, _) => task.toFirestore(),
            ),
        super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final snapshot = await _tasksCollection.get();
    state = snapshot.docs.map((doc) => doc.data()).toList();
  }

  void reload() {
    _loadTasks();
  }

  void addTask(
    String text, {
    String? tags,
    DateTime? dueDate,
    String category = 'task',
    String? note,
  }) async {
    final task = Task()
      ..text = text
      ..dueDate = dueDate ?? DateTime.now()
      ..tags = tags?.split(' ').where((t) => t.startsWith('#')).toList() ?? []
      ..category = category
      ..note = note
      ..status = 'pending'
      ..lastModified = DateTime.now();

    final docRef = await _tasksCollection.add(task);
    task.id = docRef.id;
    
    state = [...state, task];
  }

  /// Add a pre-constructed Task object (useful for adding tasks with additional fields)
  void addTaskObject(Task task) async {
    task.lastModified = DateTime.now();
    final docRef = await _tasksCollection.add(task);
    task.id = docRef.id;
    
    state = [...state, task];
  }

  void toggleTaskStatus(Task task) async {
    task.status = task.status == 'pending' ? 'done' : 'pending';
    task.lastModified = DateTime.now();
    
    if (task.id != null) {
      await _tasksCollection.doc(task.id).set(task);
    }
    
    state = [
      for (final t in state)
        if (t.id == task.id) task else t,
    ];
  }

  void updateTask(
    Task task,
    String newText,
    String newTags, {
    DateTime? dueDate,
    String? category,
    String? note,
  }) async {
    task.text = newText;
    task.tags = newTags.split(' ').where((t) => t.startsWith('#')).toList();
    if (dueDate != null) {
      task.dueDate = dueDate;
    }
    if (category != null) {
      task.category = category;
    }
    task.note = note;
    task.lastModified = DateTime.now();
    
    if (task.id != null) {
      await _tasksCollection.doc(task.id).set(task);
    }

    state = [
      for (final t in state)
        if (t.id == task.id) task else t,
    ];
  }

  void migrateTask(Task task, DateTime newDueDate) async {
    // Create a new task for the new date
    final newTask = Task()
      ..text = task.text
      ..dueDate = newDueDate
      ..tags = task.tags
      ..category = task.category
      ..note = task.note
      ..status = 'pending'
      ..lastModified = DateTime.now();

    // Update the original task's status to 'migrated'
    task.status = 'migrated';
    task.lastModified = DateTime.now();

    if (task.id != null) {
      await _tasksCollection.doc(task.id).set(task);
    }
    final newDocRef = await _tasksCollection.add(newTask);
    newTask.id = newDocRef.id;

    // Update the state
    state = [...state.where((t) => t.id != task.id), task, newTask];
  }

  void cancelTask(Task task) async {
    task.status = 'canceled';
    task.lastModified = DateTime.now();
    
    if (task.id != null) {
      await _tasksCollection.doc(task.id).set(task);
    }
    
    state = [
      for (final t in state)
        if (t.id == task.id) task else t,
    ];
  }

  void uncancelTask(Task task) async {
    task.status = 'pending';
    task.lastModified = DateTime.now();
    
    if (task.id != null) {
      await _tasksCollection.doc(task.id).set(task);
    }
    
    state = [
      for (final t in state)
        if (t.id == task.id) task else t,
    ];
  }

  void deleteTask(Task task) async {
    if (task.id != null) {
      await _tasksCollection.doc(task.id).delete();
    }
    
    state = state.where((t) => t.id != task.id).toList();
  }
}
