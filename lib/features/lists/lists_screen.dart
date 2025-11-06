import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/list.dart';
import 'package:keystone/providers/list_provider.dart';
import 'package:keystone/features/lists/list_detail_screen.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddListDialog({required bool isTemporary}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final listService = ref.read(listServiceProvider);

    if (listService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create lists')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTemporary ? 'New Temporary List' : 'New List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: isTemporary ? 'e.g., Grocery Shopping' : 'e.g., Favorite Books',
              ),
              autofocus: true,
            ),
            if (!isTemporary) ...[
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this list for?',
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
              
              final newList = AppList(
                title: titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                isTemporary: isTemporary,
              );
              
              await listService.addList(newList);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(listsProvider);
    final listService = ref.watch(listServiceProvider);

    return listsAsync.when(
      data: (lists) => _buildContent(context, lists, listService),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<AppList> lists, ListService? listService) {
    final permanentLists = lists.where((list) => !list.isTemporary).toList();
    final temporaryLists = lists.where((list) => list.isTemporary).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lists', icon: Icon(Icons.list_alt)),
            Tab(text: 'Temporary', icon: Icon(Icons.playlist_add_check)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListsTab(permanentLists, false),
          _buildListsTab(temporaryLists, true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(
          isTemporary: _tabController.index == 1,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListsTab(List<AppList> lists, bool isTemporary) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTemporary ? Icons.playlist_add_check : Icons.list_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isTemporary ? 'No temporary lists' : 'No lists yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTemporary
                  ? 'Create quick lists for shopping, todos, etc.'
                  : 'Create permanent lists for favorites, collections, etc.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: lists.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final list = lists[index];
        return _buildListCard(list);
      },
    );
  }

  Widget _buildListCard(AppList list) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: Icon(
          list.isTemporary ? Icons.playlist_add_check : Icons.list_alt,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(list.title),
        subtitle: list.description != null
            ? Text(
                list.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (list.items.isNotEmpty && !list.isTemporary)
              Chip(
                label: Text('${list.items.length}'),
                labelStyle: const TextStyle(fontSize: 12),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListDetailScreen(list: list),
            ),
          );
        },
        onLongPress: () => _showDeleteConfirmation(list),
      ),
    );
  }

  void _showDeleteConfirmation(AppList list) {
    final listService = ref.read(listServiceProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (listService != null && list.id != null) {
                await listService.deleteList(list.id!);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
