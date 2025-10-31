import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keystone/features/journal/journal_detail_screen.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/providers/journal_provider.dart';

class JournalTab extends ConsumerWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalEntryListProvider);

    return Scaffold(
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Tooltip(
            message: entry.body,
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalDetailScreen(entry: entry),
                  ),
                );
              },
              onLongPress: () =>
                  _showJournalEntryDialog(context, ref, entry: entry),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJournalEntryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
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
                            labelText: 'Tags (e.g. #work #home)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              if (entry != null) {
                                ref
                                    .read(journalEntryListProvider.notifier)
                                    .addImageToJournalEntry(
                                      entry,
                                      pickedFile.path,
                                    );
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Insert Picture'),
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
                        onPressed: () {
                          ref
                              .read(journalEntryListProvider.notifier)
                              .deleteJournalEntry(entry);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (bodyController.text.isNotEmpty) {
                          if (entry == null) {
                            ref
                                .read(journalEntryListProvider.notifier)
                                .addJournalEntry(
                                  bodyController.text,
                                  tags: tagsController.text,
                                );
                          } else {
                            ref
                                .read(journalEntryListProvider.notifier)
                                .updateJournalEntry(
                                  entry,
                                  bodyController.text,
                                  newTags: tagsController.text,
                                );
                          }
                          Navigator.pop(context);
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
