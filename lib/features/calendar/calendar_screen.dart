import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keystone/features/journal/journal_detail_screen.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/providers/journal_provider.dart';
import 'package:keystone/providers/note_provider.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Offset _tapPosition = Offset.zero;

  // Track expanded state for each category
  final Map<String, bool> _expandedCategories = {
    'Tasks': true,
    'Notes': true,
    'Journal Entries': true,
  };

  Map<String, List<dynamic>> _getGroupedEventsForDay(DateTime day) {
    final tasksAsync = ref.read(taskListProvider);
    final notesAsync = ref.read(noteListProvider);
    final journalEntriesAsync = ref.read(journalEntryListProvider);

    final tasks = tasksAsync.asData?.value ?? [];
    final notes = notesAsync.asData?.value ?? [];
    final journalEntries = journalEntriesAsync.asData?.value ?? [];

    final dayTasks = tasks
        .where((task) => isSameDay(task.dueDate, day))
        .toList();
    final dayNotes = notes
        .where((note) => isSameDay(note.creationDate, day))
        .toList();
    final dayJournalEntries = journalEntries
        .where((entry) => isSameDay(entry.creationDate, day))
        .toList();

    return {
      'Tasks': dayTasks,
      'Notes': dayNotes,
      'Journal Entries': dayJournalEntries,
    };
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final groupedEvents = _getGroupedEventsForDay(day);
    return groupedEvents.values.expand((list) => list).toList();
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Task task) {
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
        );
        break;
      case 'migrated':
        leading = const Icon(Icons.chevron_right, color: Colors.grey);
        titleStyle = const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
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
        );
        isInteractive = false;
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
        // Store tap position for context menu
        _tapPosition = details.globalPosition;
      },
      onTap: isInteractive
          ? () {
              // Click anywhere on item opens context menu
              _showTaskContextMenu(context, ref, task);
            }
          : null,
      child: ListTile(
        leading: GestureDetector(
          onTap: isInteractive
              ? () async {
                  // Only icon click toggles task status
                  final taskService = ref.read(taskServiceProvider);
                  if (taskService != null && task.id != null) {
                    await taskService.toggleTaskStatus(task.id!, task.status);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: leading,
          ),
        ),
        title: Text(task.text, style: titleStyle),
      ),
    );
  }

  void _showTaskContextMenu(BuildContext context, WidgetRef ref, Task task) {
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
        // Show Migrate only for pending tasks
        if (task.status == 'pending')
          const PopupMenuItem<String>(
            value: 'migrate',
            child: ListTile(
              leading: Icon(Icons.chevron_right),
              title: Text('Migrate'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        // Show Cancel only for pending tasks
        if (task.status == 'pending')
          const PopupMenuItem<String>(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.block),
              title: Text('Cancel'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        // Show Undo Cancel only for canceled tasks
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
          if (task.id != null) {
            await taskService.toggleTaskStatus(task.id!, task.status);
          }
          break;
        case 'edit':
          _showAddTaskDialog(context, ref, task: task);
          break;
        case 'migrate':
          _showMigrateDialog(context, ref, task);
          break;
        case 'cancel':
          if (task.id != null) {
            await taskService.cancelTask(task.id!);
          }
          break;
        case 'uncancel':
          if (task.id != null) {
            await taskService.uncancelTask(task.id!);
          }
          break;
        case 'delete':
          if (task.id != null) {
            await taskService.deleteTask(task.id!);
          }
          break;
      }
    });
  }

  // Old modal bottom sheet version - can be removed
  void _showTaskContextMenuOld(BuildContext context, WidgetRef ref, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTaskDialog(context, ref, task: task);
                },
              ),
              // Show Migrate only for pending tasks
              if (task.status == 'pending')
                ListTile(
                  leading: const Icon(Icons.chevron_right),
                  title: const Text('Migrate'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMigrateDialog(context, ref, task);
                  },
                ),
              // Show Cancel only for pending tasks
              if (task.status == 'pending')
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Cancel'),
                  onTap: () async {
                    Navigator.pop(context);
                    final taskService = ref.read(taskServiceProvider);
                    if (taskService != null && task.id != null) {
                      await taskService.cancelTask(task.id!);
                    }
                  },
                ),
              // Show Undo Cancel only for canceled tasks
              if (task.status == 'canceled')
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Undo Cancel'),
                  onTap: () async {
                    Navigator.pop(context);
                    final taskService = ref.read(taskServiceProvider);
                    if (taskService != null && task.id != null) {
                      await taskService.uncancelTask(task.id!);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  final taskService = ref.read(taskServiceProvider);
                  if (taskService != null && task.id != null) {
                    await taskService.deleteTask(task.id!);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMigrateDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: task.dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (newDate != null) {
      final taskService = ref.read(taskServiceProvider);
      if (taskService != null && task.id != null) {
        await taskService.migrateTask(task.id!, newDate);
      }
    }
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref, {Task? task}) {
    final TextEditingController controller = TextEditingController(
      text: task?.text,
    );
    final TextEditingController tagsController = TextEditingController(
      text: task?.tags.join(' '),
    );
    final TextEditingController noteController = TextEditingController(
      text: task?.note,
    );
    DateTime? dueDate = task?.dueDate ?? DateTime.now();
    String category = task?.category ?? 'task'; // Default to 'task'

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
                child: AlertDialog(
                  title: Text(task == null ? 'Add Item' : 'Edit Item'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'task', label: Text('Task')),
                            ButtonSegment(value: 'event', label: Text('Event')),
                          ],
                          selected: {category},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              category = newSelection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Task',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (e.g. #work #home)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Due Date: '),
                            TextButton(
                              onPressed: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    dueDate = selectedDate;
                                  });
                                }
                              },
                              child: Text(
                                dueDate != null
                                    ? DateFormat.yMMMd().format(dueDate!)
                                    : 'Select Date',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (controller.text.isNotEmpty && dueDate != null) {
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
                            } else if (task.id != null) {
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskListProvider).asData?.value ?? [];
    final groupedEvents = _getGroupedEventsForDay(_selectedDay);
    final List<Widget> eventWidgets = [];

    groupedEvents.forEach((header, events) {
      if (events.isNotEmpty) {
        final categoryEvents = <Widget>[];

        for (final event in events) {
          if (event is Task) {
            categoryEvents.add(_buildTaskItem(context, ref, event));
          } else if (event is Note) {
            categoryEvents.add(
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  _tapPosition = details.globalPosition;
                },
                onTap: () => _showNoteContextMenu(context, ref, event),
                child: ListTile(
                  title: Text(event.optionalTitle ?? 'Note'),
                  subtitle: Text(
                    event.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          } else if (event is JournalEntry) {
            categoryEvents.add(
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  _tapPosition = details.globalPosition;
                },
                onTap: () => _showJournalContextMenu(context, ref, event),
                child: ListTile(
                  title: Text(DateFormat.yMMMd().format(event.creationDate)),
                  subtitle: Text(
                    event.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }
        }

        eventWidgets.add(
          ExpansionTile(
            initiallyExpanded: _expandedCategories[header] ?? true,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedCategories[header] = expanded;
              });
            },
            title: Text(
              '$header (${events.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: categoryEvents,
          ),
        );
      }
    });

    // Build the calendar widget
    final calendarWidget = Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        eventLoader: _getEventsForDay,
        headerVisible: true,
        daysOfWeekHeight: 40,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }
            return null;
          },
          defaultBuilder: (context, day, focusedDay) {
            final now = DateTime.now();
            final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
            final hasPending = allTasks.any(
              (task) =>
                  isSameDay(task.dueDate, day) && task.status == 'pending',
            );

            if (isPast && hasPending) {
              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
            return null;
          },
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
      ),
    );

    // Build the events list widget
    final eventsListWidget = eventWidgets.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No items for ${DateFormat.yMMMd().format(_selectedDay)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        : ListView(children: eventWidgets);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use side-by-side layout for wider screens (desktop/tablet)
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar on the left
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: calendarWidget),
                    ),
                  ),
                ),
                // Vertical divider
                const VerticalDivider(width: 1),
                // Events on the right
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          DateFormat.yMMMd().format(_selectedDay),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(child: eventsListWidget),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Use vertical layout for narrow screens (mobile)
            return Column(
              children: [
                calendarWidget,
                const SizedBox(height: 8.0),
                Expanded(child: eventsListWidget),
              ],
            );
          }
        },
      ),
    );
  }

  void _showNoteContextMenu(BuildContext context, WidgetRef ref, Note note) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
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
      
      final noteService = ref.read(noteServiceProvider);
      if (noteService == null) return;
      
      switch (value) {
        case 'edit':
          // Navigate to notes tab or show edit dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit note functionality - navigate to Notes tab')),
          );
          break;
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Note'),
              content: const Text('Are you sure you want to delete this note?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true && note.id != null) {
            await noteService.deleteNote(note.id!);
          }
          break;
      }
    });
  }

  void _showJournalContextMenu(BuildContext context, WidgetRef ref, JournalEntry entry) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('View Details'),
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
      
      final journalService = ref.read(journalServiceProvider);
      if (journalService == null) return;
      
      switch (value) {
        case 'view':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailScreen(entry: entry),
            ),
          );
          break;
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit journal functionality - navigate to Journal tab')),
          );
          break;
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Journal Entry'),
              content: const Text('Are you sure you want to delete this journal entry?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true && entry.id != null) {
            await journalService.deleteJournalEntry(entry.id!);
          }
          break;
      }
    });
  }
}
