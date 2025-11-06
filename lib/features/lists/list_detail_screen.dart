import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/list.dart';
import 'package:keystone/providers/list_provider.dart';
import 'package:intl/intl.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final AppList list;

  const ListDetailScreen({super.key, required this.list});

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  Offset _tapPosition = Offset.zero;

  @override
  void dispose() {
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemController.text.trim().isEmpty) return;
    
    final listService = ref.read(listServiceProvider);
    if (listService == null || widget.list.id == null) return;
    
    if (widget.list.isTemporary) {
      // For temporary lists, add to ListItem collection
      final newItem = ListItem(
        listId: widget.list.id!,
        text: _itemController.text.trim(),
      );
      listService.addListItem(newItem);
    } else {
      // For permanent lists, add to items array
      // Get the current list state from the provider to avoid stale data
      final currentListAsync = ref.read(singleListProvider(widget.list.id!));
      final currentList = currentListAsync.value ?? widget.list;
      
      final newItem = PermanentListItem(text: _itemController.text.trim());
      final updatedList = currentList.copyWith(
        items: [...currentList.items, newItem],
      );
      listService.updateList(updatedList);
    }
    
    _itemController.clear();
    // Request focus back to the input field for quick successive entries
    _itemFocusNode.requestFocus();
  }

  void _showEditListDialog() {
    final titleController = TextEditingController(text: widget.list.title);
    final descriptionController = TextEditingController(text: widget.list.description ?? '');
    final listService = ref.read(listServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            if (!widget.list.isTemporary) ...[
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              
              if (listService != null) {
                final updatedList = widget.list.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );
                await listService.updateList(updatedList);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.list.isTemporary) {
      // Permanent list - watch for live updates if ID exists
      if (widget.list.id == null) {
        // No ID yet, show loading
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.list.title),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Setting up list...'),
              ],
            ),
          ),
        );
      }
      
      // Watch the list from Firestore for live updates
      final listAsync = ref.watch(singleListProvider(widget.list.id!));
      
      return listAsync.when(
        data: (list) {
          if (list == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('List not found'),
              ),
              body: const Center(child: Text('This list was deleted.')),
            );
          }
          
          return Scaffold(
            appBar: AppBar(
              title: Text(list.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditListDialog,
                ),
              ],
            ),
            body: Column(
              children: [
                if (list.description != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Text(
                      list.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          focusNode: _itemFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Add item to list...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildPermanentListItems(list),
                ),
              ],
            ),
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: Text(widget.list.title),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: Text(widget.list.title),
          ),
          body: Center(child: Text('Error: $error')),
        ),
      );
    }

    // Temporary list - check if list has an ID
    if (widget.list.id == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.list.title),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up list...'),
            ],
          ),
        ),
      );
    }

    // Temporary list - watch items from Firestore
    final itemsAsync = ref.watch(listItemsProvider(widget.list.id!));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditListDialog,
          ),
          itemsAsync.when(
            data: (items) => items.any((item) => item.isCompleted)
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () async {
                      final listService = ref.read(listServiceProvider);
                      if (listService != null && widget.list.id != null) {
                        await listService.deleteCompletedItems(widget.list.id!);
                      }
                    },
                    tooltip: 'Delete completed items',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.list.description != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Text(
                widget.list.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    focusNode: _itemFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Add item to check off...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) => _buildTemporaryListItems(items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading items: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporaryListItems(List<ListItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items yet. Add items above.'),
      );
    }

    // Separate completed and incomplete items
    final incompleteItems = items.where((item) => !item.isCompleted).toList();
    final completedItems = items.where((item) => item.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...incompleteItems.map((item) => _buildCheckableItem(item, false)),
        if (completedItems.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Completed (${completedItems.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          ...completedItems.map((item) => _buildCheckableItem(item, true)),
        ],
      ],
    );
  }

  Widget _buildCheckableItem(ListItem item, bool isCompleted) {
    final listService = ref.read(listServiceProvider);
    
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // Store tap position for context menu
        _tapPosition = details.globalPosition;
      },
      onTap: () {
        // Click anywhere on the item (except checkbox) opens context menu at tap location
        _showTemporaryItemContextMenu(context, _tapPosition, item, listService);
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) async {
            // Only checkbox click toggles completion
            if (listService != null && item.id != null) {
              await listService.toggleListItem(item.id!, item.isCompleted);
            }
          },
        ),
        title: Text(
          item.text,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            if (listService != null && item.id != null) {
              await listService.deleteListItem(item.id!);
            }
          },
        ),
      ),
    );
  }

  void _showTemporaryItemContextMenu(
    BuildContext context,
    Offset position,
    ListItem item,
    ListService? listService,
  ) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(item.isCompleted ? Icons.check_box_outline_blank : Icons.check_box),
            title: Text(item.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () async {
            if (listService != null && item.id != null) {
              await listService.toggleListItem(item.id!, item.isCompleted);
            }
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () async {
            if (listService != null && item.id != null) {
              await listService.deleteListItem(item.id!);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPermanentListItems(AppList list) {
    if (list.items.isEmpty) {
      return const Center(
        child: Text('No items yet. Add items above.'),
      );
    }

    final listService = ref.read(listServiceProvider);
    
    // Sort items: uncompleted first, completed at bottom
    final sortedItems = List<PermanentListItem>.from(list.items);
    sortedItems.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        // If both have same completion status, maintain original order (by createdAt)
        return a.createdAt.compareTo(b.createdAt);
      }
      // Uncompleted items come first
      return a.isCompleted ? 1 : -1;
    });

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedItems.length,
      onReorder: (oldIndex, newIndex) async {
        if (listService == null) return;
        
        final items = List<PermanentListItem>.from(sortedItems);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
        
        final updatedList = list.copyWith(items: items);
        await listService.updateList(updatedList);
      },
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        // Use index as key to avoid duplicate issues with same text
        return GestureDetector(
          key: ValueKey('item_$index'),
          onTapDown: (TapDownDetails details) {
            // Store tap position for context menu
            _tapPosition = details.globalPosition;
          },
          onTap: () {
            // Click anywhere on the item (except checkbox) opens context menu at tap location
            _showPermanentItemContextMenu(context, _tapPosition, item, list, listService);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: (value) async {
                  // Only checkbox click toggles completion
                  if (listService == null) return;
                  
                  final isNowCompleted = value ?? false;
                  final items = List<PermanentListItem>.from(list.items);
                  
                  // Find the item in the original list
                  final originalIndex = items.indexWhere((i) => 
                    i.text == item.text && 
                    i.createdAt == item.createdAt
                  );
                  
                  if (originalIndex == -1) return;
                  
                  // Update the item with completion status and date
                  final updatedItem = items[originalIndex].copyWith(
                    isCompleted: isNowCompleted,
                    completedAt: isNowCompleted ? DateTime.now() : null,
                  );
                  
                  // Remove from current position
                  items.removeAt(originalIndex);
                  
                  // If completing, add to end; if uncompleting, add to beginning
                  if (isNowCompleted) {
                    items.add(updatedItem);
                  } else {
                    items.insert(0, updatedItem);
                  }
                  
                  final updatedList = list.copyWith(items: items);
                  await listService.updateList(updatedList);
                },
              ),
              title: Text(
                item.text,
                style: TextStyle(
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  color: item.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: item.isCompleted && item.completedAt != null
                  ? Text(
                      'Completed: ${DateFormat('MMM d, y').format(item.completedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      if (listService == null) return;
                      
                      final items = List<PermanentListItem>.from(list.items);
                      // Find and remove the item from the original list
                      final originalIndex = items.indexWhere((i) => 
                        i.text == item.text && 
                        i.createdAt == item.createdAt
                      );
                      
                      if (originalIndex != -1) {
                        items.removeAt(originalIndex);
                        final updatedList = list.copyWith(items: items);
                        await listService.updateList(updatedList);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPermanentItemContextMenu(
    BuildContext context,
    Offset position,
    PermanentListItem item,
    AppList list,
    ListService? listService,
  ) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(item.isCompleted ? Icons.check_box_outline_blank : Icons.check_box),
            title: Text(item.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () async {
            if (listService == null) return;
            
            final items = List<PermanentListItem>.from(list.items);
            
            // Find the item in the original list
            final originalIndex = items.indexWhere((i) => 
              i.text == item.text && 
              i.createdAt == item.createdAt
            );
            
            if (originalIndex == -1) return;
            
            // Toggle completion status
            final updatedItem = items[originalIndex].copyWith(
              isCompleted: !item.isCompleted,
              completedAt: !item.isCompleted ? DateTime.now() : null,
            );
            
            // Remove from current position
            items.removeAt(originalIndex);
            
            // If completing, add to end; if uncompleting, add to beginning
            if (!item.isCompleted) {
              items.add(updatedItem);
            } else {
              items.insert(0, updatedItem);
            }
            
            final updatedList = list.copyWith(items: items);
            await listService.updateList(updatedList);
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () async {
            if (listService == null) return;
            
            final items = List<PermanentListItem>.from(list.items);
            // Find and remove the item from the original list
            final originalIndex = items.indexWhere((i) => 
              i.text == item.text && 
              i.createdAt == item.createdAt
            );
            
            if (originalIndex != -1) {
              items.removeAt(originalIndex);
              final updatedList = list.copyWith(items: items);
              await listService.updateList(updatedList);
            }
          },
        ),
      ],
    );
  }
}
