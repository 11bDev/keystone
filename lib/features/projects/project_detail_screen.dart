import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/project.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:keystone/providers/note_provider.dart';
import 'package:keystone/providers/journal_provider.dart';
import 'package:keystone/features/journal/journal_detail_screen.dart';
import 'package:keystone/widgets/app_navigation_actions.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getProjectTag() {
    return '-${widget.project.name.toLowerCase().replaceAll(' ', '')}';
  }

  List<Task> _getProjectTasks(List<Task> allTasks) {
    final projectTag = _getProjectTag();
    return allTasks.where((task) {
      return task.tags.any((tag) => tag.toLowerCase() == projectTag);
    }).toList();
  }

  List<Note> _getProjectNotes(List<Note> allNotes) {
    final projectTag = _getProjectTag();
    return allNotes.where((note) {
      return note.tags.any((tag) => tag.toLowerCase() == projectTag);
    }).toList();
  }

  List<JournalEntry> _getProjectJournalEntries(List<JournalEntry> allEntries) {
    final projectTag = _getProjectTag();
    return allEntries.where((entry) {
      return entry.tags.any((tag) => tag.toLowerCase() == projectTag);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final notesAsync = ref.watch(noteListProvider);
    final journalAsync = ref.watch(journalEntryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: const [
          AppNavigationActions(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tasks', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Notes', icon: Icon(Icons.note)),
            Tab(text: 'Journal', icon: Icon(Icons.book)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.project.description != null && widget.project.description!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.project.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.label,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Project Tag: ${_getProjectTag()}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tasks Tab
                _buildTasksTab(tasksAsync),
                // Notes Tab
                _buildNotesTab(notesAsync),
                // Journal Tab
                _buildJournalTab(journalAsync),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0: // Tasks
              _showAddTaskDialog(context, ref);
              break;
            case 1: // Notes
              _showAddNoteDialog(context, ref);
              break;
            case 2: // Journal
              _showAddJournalDialog(context, ref);
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTasksTab(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (allTasks) {
        final projectTasks = _getProjectTasks(allTasks);

        if (projectTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks in this project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create a task',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: projectTasks.length,
          itemBuilder: (context, index) {
            final task = projectTasks[index];
            return _buildTaskItem(context, task);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    Widget leading;
    TextStyle? titleStyle;
    bool isInteractive = true;

    switch (task.status) {
      case 'done':
        if (task.category == 'event') {
          leading = const Icon(Icons.add, color: Colors.grey);
        } else {
          leading = const Icon(Icons.clear, color: Colors.grey);
        }
        titleStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
          fontSize: 18,
        );
        break;
      case 'migrated':
        leading = const Icon(Icons.chevron_right, color: Colors.grey);
        titleStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
          fontSize: 18,
        );
        isInteractive = false;
        break;
      case 'canceled':
        leading = const Text(
          '/',
          style: TextStyle(fontSize: 24, color: Colors.grey),
        );
        titleStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
          fontSize: 18,
        );
        break;
      case 'pending':
      default:
        if (task.category == 'event') {
          leading = Icon(
            Icons.remove,
            color: Theme.of(context).colorScheme.primary,
          );
        } else {
          leading = Icon(
            Icons.circle,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          );
        }
        break;
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _tapPosition = details.globalPosition;
      },
      onTap: isInteractive
          ? () {
              _showTaskContextMenu(context, task);
            }
          : null,
      child: ListTile(
        leading: GestureDetector(
          onTap: isInteractive
              ? () async {
                  final taskService = ref.read(taskServiceProvider);
                  if (taskService != null) {
                    await taskService.toggleTaskStatus(task.id!, task.status);
                  }
                }
              : null,
          child: leading,
        ),
        title: Text(task.text, style: titleStyle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(task.dueDate),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (task.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  task.tags.join(' '),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (task.note != null && task.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  task.note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTaskContextMenu(BuildContext context, Task task) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'toggle',
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Toggle Status'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (task.status == 'pending')
          const PopupMenuItem<String>(
            value: 'migrate',
            child: ListTile(
              leading: Icon(Icons.chevron_right),
              title: Text('Migrate'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (task.status == 'pending')
          const PopupMenuItem<String>(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.block),
              title: Text('Cancel'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (task.status == 'canceled')
          const PopupMenuItem<String>(
            value: 'uncancel',
            child: ListTile(
              leading: Icon(Icons.undo),
              title: Text('Undo Cancel'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
      
      final taskService = ref.read(taskServiceProvider);
      if (taskService == null) return;
      
      switch (value) {
        case 'toggle':
          await taskService.toggleTaskStatus(task.id!, task.status);
          break;
        case 'edit':
          _showAddTaskDialog(context, ref, task: task);
          break;
        case 'migrate':
          _showMigrateDialog(context, task);
          break;
        case 'cancel':
          await taskService.cancelTask(task.id!);
          break;
        case 'uncancel':
          await taskService.uncancelTask(task.id!);
          break;
        case 'delete':
          await taskService.deleteTask(task.id!);
          break;
      }
    });
  }

  void _showMigrateDialog(BuildContext context, Task task) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Migrate Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Move "${task.text}" to:'),
                  const SizedBox(height: 16),
                  Text(
                    'New Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = DateTime.now().add(const Duration(days: 1));
                          });
                        },
                        child: const Text('Tomorrow'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final taskService = ref.read(taskServiceProvider);
                    if (taskService != null) {
                      await taskService.migrateTask(task.id!, selectedDate);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Migrate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotesTab(AsyncValue<List<Note>> notesAsync) {
    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (allNotes) {
        final projectNotes = _getProjectNotes(allNotes);

        if (projectNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes in this project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create a note',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: projectNotes.length,
          itemBuilder: (context, index) {
            final note = projectNotes[index];
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                _tapPosition = details.globalPosition;
              },
              onTap: () {
                _showNoteContextMenu(context, note);
              },
              child: ListTile(
                leading: const Icon(Icons.note),
                title: Text(note.optionalTitle ?? 'Untitled'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          note.tags.join(' '),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNoteContextMenu(BuildContext context, Note note) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
      
      final noteService = ref.read(noteServiceProvider);
      if (noteService == null) return;
      
      switch (value) {
        case 'edit':
          _showAddNoteDialog(context, ref, note: note);
          break;
        case 'delete':
          await noteService.deleteNote(note.id!);
          break;
      }
    });
  }

  Widget _buildJournalTab(AsyncValue<List<JournalEntry>> journalAsync) {
    return journalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (allEntries) {
        final projectEntries = _getProjectJournalEntries(allEntries);

        if (projectEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No journal entries in this project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create an entry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: projectEntries.length,
          itemBuilder: (context, index) {
            final entry = projectEntries[index];
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                _tapPosition = details.globalPosition;
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalDetailScreen(entry: entry),
                  ),
                );
              },
              onLongPress: () {
                _showJournalContextMenu(context, entry);
              },
              child: ListTile(
                leading: const Icon(Icons.book),
                title: Text(
                  entry.body.length > 50 
                    ? '${entry.body.substring(0, 50)}...' 
                    : entry.body,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(entry.creationDate),
                    ),
                    if (entry.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          entry.tags.join(' '),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJournalContextMenu(BuildContext context, JournalEntry entry) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
      
      final journalService = ref.read(journalServiceProvider);
      if (journalService == null) return;
      
      switch (value) {
        case 'edit':
          _showAddJournalDialog(context, ref, entry: entry);
          break;
        case 'delete':
          await journalService.deleteJournalEntry(entry.id!);
          break;
      }
    });
  }

  // Task Dialog
  void _showAddTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final TextEditingController controller = TextEditingController(
      text: task?.text,
    );
    final TextEditingController tagsController = TextEditingController(
      text: task?.tags.join(' ') ?? _getProjectTag(),
    );
    final TextEditingController noteController = TextEditingController(
      text: task?.note,
    );
    DateTime? dueDate = task?.dueDate ?? DateTime.now();
    String category = task?.category ?? 'task';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task == null ? 'Add Task' : 'Edit Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'task',
                                  label: Text('Task'),
                                ),
                                ButtonSegment(
                                  value: 'event',
                                  label: Text('Event'),
                                ),
                              ],
                              selected: {category},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  category = newSelection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                            ),
                            TextField(
                              controller: tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Tags (e.g. #work -myproject)',
                                hintText: 'Use # for tags, - for projects',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note (optional)',
                                hintText: 'Add a short note...',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Due Date: ${dueDate!.toLocal().toString().split(' ')[0]}',
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      dueDate = DateTime.now();
                                    });
                                  },
                                  child: const Text('Today'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      dueDate = DateTime.now().add(
                                        const Duration(days: 1),
                                      );
                                    });
                                  },
                                  child: const Text('Tomorrow'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate!,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        dueDate = pickedDate;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            if (controller.text.isNotEmpty) {
                              final taskService = ref.read(taskServiceProvider);
                              if (taskService != null) {
                                if (task == null) {
                                  await taskService.addTask(
                                    controller.text,
                                    tags: tagsController.text,
                                    dueDate: dueDate,
                                    category: category,
                                    note: noteController.text.isEmpty
                                        ? null
                                        : noteController.text,
                                  );
                                } else {
                                  await taskService.updateTask(
                                    task.id!,
                                    controller.text,
                                    tagsController.text,
                                    dueDate: dueDate,
                                    category: category,
                                    note: noteController.text.isEmpty
                                        ? null
                                        : noteController.text,
                                  );
                                }
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: Text(task == null ? 'Add' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Note Dialog
  void _showAddNoteDialog(BuildContext context, WidgetRef ref, {Note? note}) {
    final TextEditingController titleController = TextEditingController(
      text: note?.optionalTitle,
    );
    final TextEditingController contentController = TextEditingController(
      text: note?.content,
    );
    final TextEditingController tagsController = TextEditingController(
      text: note?.tags.join(' ') ?? _getProjectTag(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note == null ? 'Add Note' : 'Edit Note',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title (optional)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contentController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                          ),
                          maxLines: 5,
                        ),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (e.g. #work -myproject)',
                            hintText: 'Use # for tags, - for projects',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (contentController.text.isNotEmpty) {
                          final noteService = ref.read(noteServiceProvider);
                          if (noteService != null) {
                            if (note == null) {
                              await noteService.addNote(
                                contentController.text,
                                title: titleController.text.isEmpty
                                    ? null
                                    : titleController.text,
                                tags: tagsController.text,
                              );
                            } else {
                              await noteService.updateNote(
                                note.id!,
                                contentController.text,
                                newTitle: titleController.text.isEmpty
                                    ? null
                                    : titleController.text,
                                newTags: tagsController.text,
                              );
                            }
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text(note == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Journal Dialog
  void _showAddJournalDialog(BuildContext context, WidgetRef ref, {JournalEntry? entry}) {
    final TextEditingController bodyController = TextEditingController(
      text: entry?.body,
    );
    final TextEditingController tagsController = TextEditingController(
      text: entry?.tags.join(' ') ?? _getProjectTag(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry == null ? 'Add Journal Entry' : 'Edit Journal Entry',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: bodyController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Entry',
                          ),
                          maxLines: 5,
                        ),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (e.g. #work -myproject)',
                            hintText: 'Use # for tags, - for projects',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (bodyController.text.isNotEmpty) {
                          final journalService = ref.read(journalServiceProvider);
                          if (journalService != null) {
                            if (entry == null) {
                              await journalService.addJournalEntry(
                                bodyController.text,
                                tags: tagsController.text,
                              );
                            } else {
                              await journalService.updateJournalEntry(
                                entry.id!,
                                bodyController.text,
                                newTags: tagsController.text,
                              );
                            }
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text(entry == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
