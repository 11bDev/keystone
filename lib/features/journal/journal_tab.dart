import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keystone/features/journal/journal_detail_screen.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/providers/journal_provider.dart';

class JournalTab extends ConsumerStatefulWidget {
  const JournalTab({super.key});

  @override
  ConsumerState<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends ConsumerState<JournalTab> {
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalEntryListProvider);

    return entriesAsync.when(
      data: (entries) => Scaffold(
        body: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
          return Tooltip(
            message: entry.body,
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                // Store tap position for context menu
                _tapPosition = details.globalPosition;
              },
              onTap: () => _showJournalContextMenu(context, ref, entry),
              child: ListTile(
                title: Text(
                  DateFormat('d MMM yyyy, hh:mm a').format(entry.creationDate),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.tags.isNotEmpty)
                      Text(
                        entry.tags.join(' '),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJournalEntryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    ),
    loading: () => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Scaffold(
      body: Center(child: Text('Error loading journal entries: $error')),
    ),
  );
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
          _showJournalEntryDialog(context, ref, entry: entry);
          break;
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Journal Entry'),
              content: const Text(
                'Are you sure you want to delete this journal entry?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final journalService = ref.read(journalServiceProvider);
            if (journalService != null && entry.id != null) {
              await journalService.deleteJournalEntry(entry.id!);
            }
          }
          break;
      }
    });
  }

  void _showJournalEntryDialog(
    BuildContext context,
    WidgetRef ref, {
    JournalEntry? entry,
  }) {
    final bodyController = TextEditingController(text: entry?.body);
    final tagsController = TextEditingController(text: entry?.tags.join(' '));

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
                          decoration: const InputDecoration(
                            labelText: 'Body',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 10,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: tagsController,
                            decoration: const InputDecoration(
                              labelText: 'Tags (e.g. #work @myproject)',
                              hintText: 'Use # for tags, @ for projects',
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
                    if (entry != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final journalService = ref.read(journalServiceProvider);
                          if (journalService != null && entry.id != null) {
                            await journalService.deleteJournalEntry(entry.id!);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
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
                            } else if (entry.id != null) {
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
