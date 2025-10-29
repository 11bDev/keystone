import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/providers/sync_provider.dart';

final taskListProvider = StateNotifierProvider<TaskListNotifier, List<Task>>((
  ref,
) {
  return TaskListNotifier(ref);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final Box<Task> _box = Hive.box<Task>('tasks');
  final Ref _ref;
  
  TaskListNotifier(this._ref) : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    state = _box.values.toList();
  }

  void reload() {
    _loadTasks();
  }

  Future<void> _triggerAutoSync() async {
    try {
      await _ref.read(syncNotifierProvider.notifier).autoSync();
    } catch (e) {
      // Silently fail - auto-sync is best-effort
    }
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
      ..status = 'pending';

    await _box.add(task);
    state = [...state, task];
    await _triggerAutoSync();
  }

  void toggleTaskStatus(Task task) async {
    task.status = task.status == 'pending' ? 'done' : 'pending';
    await task.save();
    state = [
      for (final t in state)
        if (t.key == task.key) task else t,
    ];
    await _triggerAutoSync();
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
    await task.save();
    state = [
      for (final t in state)
        if (t.key == task.key) task else t,
    ];
    await _triggerAutoSync();
  }

  void migrateTask(Task task, DateTime newDueDate) async {
    // Create a new task for the new date
    final newTask = Task()
      ..text = task.text
      ..dueDate = newDueDate
      ..tags = task.tags
      ..category = task.category
      ..status = 'pending';

    // Update the original task's status to 'migrated'
    task.status = 'migrated';

    await task.save();
    await _box.add(newTask);

    // Update the state
    state = [...state.where((t) => t.key != task.key), task, newTask];
    await _triggerAutoSync();
  }

  void cancelTask(Task task) async {
    task.status = 'canceled';
    await task.save();
    state = [
      for (final t in state)
        if (t.key == task.key) task else t,
    ];
    await _triggerAutoSync();
  }

  void uncancelTask(Task task) async {
    task.status = 'pending';
    await task.save();
    state = [
      for (final t in state)
        if (t.key == task.key) task else t,
    ];
    await _triggerAutoSync();
  }

  void deleteTask(Task task) async {
    await task.delete();
    state = state.where((t) => t.key != task.key).toList();
    await _triggerAutoSync();
  }
}
