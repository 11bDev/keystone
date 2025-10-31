import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/providers/note_provider.dart';

class NotesTab extends ConsumerWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteListProvider);

    return Scaffold(
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            title: Text(note.optionalTitle ?? 'Untitled Note'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.tags.isNotEmpty)
                  Text(
                    note.tags.join(' '),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            onTap: () => _showNoteDialog(context, ref, note: note),
            onLongPress: () => _showNoteContextMenu(context, ref, note),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNoteContextMenu(BuildContext context, WidgetRef ref, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showNoteDialog(context, ref, note: note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Note'),
                      content: const Text(
                        'Are you sure you want to delete this note?',
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
                    ref.read(noteListProvider.notifier).deleteNote(note);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, {Note? note}) {
    final titleController = TextEditingController(text: note?.optionalTitle);
    final contentController = TextEditingController(text: note?.content);
    final tagsController = TextEditingController(text: note?.tags.join(' '));

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
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: contentController,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (e.g. #work #home)',
                            border: OutlineInputBorder(),
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
                      onPressed: () {
                        if (contentController.text.isNotEmpty) {
                          if (note == null) {
                            ref
                                .read(noteListProvider.notifier)
                                .addNote(
                                  contentController.text,
                                  title: titleController.text.isNotEmpty
                                      ? titleController.text
                                      : null,
                                  tags: tagsController.text,
                                );
                          } else {
                            ref
                                .read(noteListProvider.notifier)
                                .updateNote(
                                  note,
                                  contentController.text,
                                  newTitle: titleController.text.isNotEmpty
                                      ? titleController.text
                                      : null,
                                  newTags: tagsController.text,
                                );
                          }
                          Navigator.pop(context);
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
}
