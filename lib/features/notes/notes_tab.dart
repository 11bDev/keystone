import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/providers/note_provider.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(noteListProvider);

    return notesAsync.when(
      data: (notes) => Scaffold(
        body: ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                // Store tap position for context menu
                _tapPosition = details.globalPosition;
              },
              onTap: () => _showNoteContextMenu(context, ref, note),
              child: ListTile(
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
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNoteDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading notes: $error')),
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
      
      switch (value) {
        case 'edit':
          _showNoteDialog(context, ref, note: note);
          break;
        case 'delete':
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
            final noteService = ref.read(noteServiceProvider);
            if (noteService != null && note.id != null) {
              await noteService.deleteNote(note.id!);
            }
          }
          break;
      }
    });
  }

  // Old modal bottom sheet version - can be removed
  void _showNoteContextMenuOld(BuildContext context, WidgetRef ref, Note note) {
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
                    final noteService = ref.read(noteServiceProvider);
                    if (noteService != null && note.id != null) {
                      await noteService.deleteNote(note.id!);
                    }
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
                            labelText: 'Tags (e.g. #work -myproject)',
                            hintText: 'Use # for tags, - for projects',
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
                      onPressed: () async {
                        if (contentController.text.isNotEmpty) {
                          final noteService = ref.read(noteServiceProvider);
                          if (noteService != null) {
                            if (note == null) {
                              await noteService.addNote(
                                contentController.text,
                                title: titleController.text.isNotEmpty
                                    ? titleController.text
                                    : null,
                                tags: tagsController.text,
                              );
                            } else if (note.id != null) {
                              await noteService.updateNote(
                                note.id!,
                                contentController.text,
                                newTitle: titleController.text.isNotEmpty
                                    ? titleController.text
                                    : null,
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
}
