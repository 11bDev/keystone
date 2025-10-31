import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:keystone/providers/sync_provider.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  int _viewIndex = 0; // 0: Today, 1: Week, 2: Month, 3: Future

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    Widget body;

    if (_viewIndex < 3) {
      final filteredTasks = _getFilteredTasks(tasks);
      body = ListView.builder(
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _buildTaskItem(context, ref, task);
        },
      );
    } else {
      body = _buildFutureView(tasks);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Today')),
              ButtonSegment(value: 1, label: Text('Week')),
              ButtonSegment(value: 2, label: Text('Month')),
              ButtonSegment(value: 3, label: Text('Future')),
            ],
            selected: {_viewIndex},
            onSelectionChanged: (newSelection) {
              setState(() {
                _viewIndex = newSelection.first;
              });
            },
          ),
        ),
      ),
      body: _viewIndex == 1 ? _buildWeekView(tasks) : body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    final now = DateTime.now();
    List<Task> filtered;
    switch (_viewIndex) {
      case 0: // Today
        filtered = tasks
            .where(
              (task) =>
                  task.dueDate.year == now.year &&
                  task.dueDate.month == now.month &&
                  task.dueDate.day == now.day,
            )
            .toList();
        break;
      case 1: // Week - handled separately with grouping
        return [];
      case 2: // Month
        filtered = tasks
            .where(
              (task) =>
                  task.dueDate.year == now.year &&
                  task.dueDate.month == now.month,
            )
            .toList();
        break;
      default:
        return []; // Future view is handled separately
    }

    // Sort tasks: pending -> done -> canceled -> migrated
    filtered.sort((a, b) {
      if (a.status == b.status) return 0;
      if (a.status == 'pending') return -1;
      if (b.status == 'pending') return 1;
      if (a.status == 'done' &&
          (b.status == 'canceled' || b.status == 'migrated'))
        return -1;
      if (b.status == 'done' &&
          (a.status == 'canceled' || a.status == 'migrated'))
        return 1;
      if (a.status == 'canceled' && b.status == 'migrated') return -1;
      if (b.status == 'canceled' && a.status == 'migrated') return 1;
      return 0;
    });

    return filtered;
  }

  Widget _buildWeekView(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Get all tasks for this week
    final weekTasks = tasks
        .where(
          (task) =>
              task.dueDate.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              task.dueDate.isBefore(endOfWeek.add(const Duration(days: 1))),
        )
        .toList();

    // Exclude migrated tasks if the new task is in the same week
    final activeTaskTexts = weekTasks
        .where((task) => task.status != 'migrated')
        .map((task) => task.text)
        .toSet();
    weekTasks.removeWhere(
      (task) =>
          task.status == 'migrated' && activeTaskTexts.contains(task.text),
    );

    // Group tasks by day
    final Map<DateTime, List<Task>> groupedByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );
      groupedByDay[day] = [];
    }

    for (final task in weekTasks) {
      final taskDay = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (groupedByDay.containsKey(taskDay)) {
        groupedByDay[taskDay]!.add(task);
      }
    }

    // Sort tasks within each day
    groupedByDay.forEach((day, dayTasks) {
      dayTasks.sort((a, b) {
        if (a.status == b.status) return 0;
        if (a.status == 'pending') return -1;
        if (b.status == 'pending') return 1;
        if (a.status == 'done' &&
            (b.status == 'canceled' || b.status == 'migrated'))
          return -1;
        if (b.status == 'done' &&
            (a.status == 'canceled' || a.status == 'migrated'))
          return 1;
        if (a.status == 'canceled' && b.status == 'migrated') return -1;
        if (b.status == 'canceled' && a.status == 'migrated') return 1;
        return 0;
      });
    });

    final sortedDays = groupedByDay.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayTasks = groupedByDay[day]!;
        final isPast = day.isBefore(today);
        final isToday = day.isAtSameMomentAs(today);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Check if there are incomplete tasks on past days
        final hasIncompleteTasks =
            isPast && dayTasks.any((task) => task.status == 'pending');

        // Determine day color - theme aware
        Color? dayColor;
        Color? textColor;
        Color? iconColor;

        if (hasIncompleteTasks) {
          dayColor = isDark
              ? Colors.red.shade900.withOpacity(0.3)
              : Colors.red.shade50;
          textColor = isDark ? Colors.red.shade300 : Colors.red.shade900;
          iconColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
        } else if (isPast) {
          dayColor = isDark
              ? Colors.grey.shade800.withOpacity(0.3)
              : Colors.grey.shade100;
          textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
          iconColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
        } else if (isToday) {
          dayColor = isDark
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade50;
          textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade900;
          iconColor = isDark ? Colors.blue.shade400 : Colors.blue.shade700;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: dayColor,
          child: ExpansionTile(
            initiallyExpanded: isToday || (dayTasks.isNotEmpty && !isPast),
            leading: Icon(
              isToday ? Icons.today : (isPast ? Icons.history : Icons.event),
              color: iconColor,
            ),
            title: Text(
              '${_getDayName(day.weekday)} ${day.month}/${day.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            subtitle: Text(
              dayTasks.isEmpty
                  ? 'No tasks'
                  : '${dayTasks.length} ${dayTasks.length == 1 ? 'task' : 'tasks'}',
              style: TextStyle(
                fontSize: 12,
                color: textColor?.withOpacity(0.7),
              ),
            ),
            children: dayTasks.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No tasks for this day',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                : dayTasks
                      .map((task) => _buildTaskItem(context, ref, task))
                      .toList(),
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayNames[weekday - 1];
  }

  Widget _buildFutureView(List<Task> tasks) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final futureTasks = tasks
        .where((task) => task.dueDate.isAfter(endOfMonth))
        .toList();

    if (futureTasks.isEmpty) {
      return const Center(child: Text('No upcoming tasks.'));
    }

    // Group by month, then by date within each month
    final Map<DateTime, Map<DateTime, List<Task>>> groupedByMonthAndDate = {};
    for (final task in futureTasks) {
      final month = DateTime(task.dueDate.year, task.dueDate.month);
      final date = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      if (groupedByMonthAndDate[month] == null) {
        groupedByMonthAndDate[month] = {};
      }
      if (groupedByMonthAndDate[month]![date] == null) {
        groupedByMonthAndDate[month]![date] = [];
      }
      groupedByMonthAndDate[month]![date]!.add(task);
    }

    final sortedMonths = groupedByMonthAndDate.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final month = sortedMonths[index];
        final dateGroups = groupedByMonthAndDate[month]!;
        final sortedDates = dateGroups.keys.toList()..sort();

        return ExpansionTile(
          title: Text(
            '${_getMonthName(month.month)} ${month.year}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: sortedDates.expand((date) {
            final dateTasks = dateGroups[date]!;
            // Format: "Monday the 21st"
            final dayOfWeek = DateFormat('EEEE').format(date); // Full day name
            final dayNumber = date.day;
            final suffix = _getDaySuffix(dayNumber);
            final dateLabel = '$dayOfWeek the $dayNumber$suffix';

            return [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 8.0,
                  bottom: 4.0,
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.8),
                  ),
                ),
              ),
              ...dateTasks.map((task) => _buildTaskItem(context, ref, task)),
            ];
          }).toList(),
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
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
        // Keep interactive to allow undo and edit
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
        titleStyle = const TextStyle(fontSize: 18);
        break;
    }

    return ListTile(
      leading: leading,
      title: Text(task.text, style: titleStyle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show date in month view
          if (_viewIndex == 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '${_getDayName(task.dueDate.weekday)} ${task.dueDate.month}/${task.dueDate.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (task.tags.isNotEmpty)
            Text(
              task.tags.join(' '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (task.note != null && task.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                task.note!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: isInteractive
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddTaskDialog(context, ref, task: task);
                } else if (value == 'migrate') {
                  _showMigrateDialog(context, ref, task);
                } else if (value == 'cancel') {
                  ref.read(taskListProvider.notifier).cancelTask(task);
                } else if (value == 'uncancel') {
                  ref.read(taskListProvider.notifier).uncancelTask(task);
                } else if (value == 'delete') {
                  ref.read(taskListProvider.notifier).deleteTask(task);
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  // Show Migrate only for pending tasks
                  if (task.status == 'pending')
                    const PopupMenuItem<String>(
                      value: 'migrate',
                      child: Text('Migrate'),
                    ),
                  // Show Cancel only for pending tasks
                  if (task.status == 'pending')
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                  // Show Undo Cancel only for canceled tasks
                  if (task.status == 'canceled')
                    const PopupMenuItem<String>(
                      value: 'uncancel',
                      child: Text('Undo Cancel'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            )
          : null,
      onTap: isInteractive
          ? () {
              ref.read(taskListProvider.notifier).toggleTaskStatus(task);
            }
          : null,
      onLongPress: isInteractive
          ? () {
              _showTaskContextMenu(context, ref, task);
            }
          : null,
    );
  }

  void _showTaskContextMenu(BuildContext context, WidgetRef ref, Task task) {
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
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(taskListProvider.notifier).cancelTask(task);
                  },
                ),
              // Show Undo Cancel only for canceled tasks
              if (task.status == 'canceled')
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Undo Cancel'),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(taskListProvider.notifier).uncancelTask(task);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(taskListProvider.notifier).deleteTask(task);
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
      ref.read(taskListProvider.notifier).migrateTask(task, newDate);
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
    bool addToGoogleCalendar = false; // Default: don't add to Google Calendar

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final syncService = ref.read(syncServiceProvider);
            final isSignedIn = syncService.isSignedIn;
            final showGoogleCalendarOption = category == 'event' && isSignedIn;

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
                      task == null ? 'Add Item' : 'Edit Item',
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
                                  // Reset checkbox if switching away from event
                                  if (category != 'event') {
                                    addToGoogleCalendar = false;
                                  }
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
                                labelText: 'Tags (e.g. #work #home)',
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
                            if (showGoogleCalendarOption) ...[
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text('Add to Google Calendar'),
                                subtitle: const Text(
                                  'Sync this event to your Google Calendar',
                                ),
                                value: addToGoogleCalendar,
                                onChanged: (value) {
                                  setState(() {
                                    addToGoogleCalendar = value ?? false;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
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
                              if (task == null) {
                                // Adding new task
                                final newTask = Task()
                                  ..text = controller.text
                                  ..tags = tagsController.text
                                      .split(' ')
                                      .where((tag) => tag.isNotEmpty)
                                      .toList()
                                  ..dueDate = dueDate!
                                  ..category = category
                                  ..note = noteController.text.isEmpty
                                      ? null
                                      : noteController.text;

                                // Add to Google Calendar if requested
                                if (addToGoogleCalendar &&
                                    category == 'event') {
                                  final calendarService =
                                      syncService.calendarService;
                                  final eventId = await calendarService
                                      .addEventToCalendar(newTask);
                                  if (eventId != null) {
                                    newTask.googleCalendarEventId = eventId;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Event added to Google Calendar',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to add to Google Calendar',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }

                                ref
                                    .read(taskListProvider.notifier)
                                    .addTaskObject(newTask);
                              } else {
                                // Updating existing task
                                ref
                                    .read(taskListProvider.notifier)
                                    .updateTask(
                                      task,
                                      controller.text,
                                      tagsController.text,
                                      dueDate: dueDate,
                                      category: category,
                                      note: noteController.text.isEmpty
                                          ? null
                                          : noteController.text,
                                    );

                                // Update in Google Calendar if it was synced
                                if (task.googleCalendarEventId != null &&
                                    category == 'event') {
                                  final calendarService =
                                      syncService.calendarService;
                                  await calendarService.updateEventInCalendar(
                                    task.googleCalendarEventId!,
                                    task,
                                  );
                                }
                              }
                              Navigator.pop(context);
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
}
