import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../providers/firestore_provider.dart';
import '../../services/firestore_service.dart';

/// Example screen demonstrating Firestore offline-first sync
///
/// This shows:
/// - Real-time updates via StreamProvider
/// - Optimistic UI updates (works offline)
/// - Sign-in state management
/// - Loading and error states
class ProjectsExampleScreen extends ConsumerWidget {
  const ProjectsExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirebaseAvailable = ref.watch(isFirebaseAvailableProvider);

    if (!isFirebaseAvailable) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Projects (Firestore Demo)'),
        ),
        body: _buildFirebaseUnavailable(),
      );
    }

    // Firebase is available, proceed with existing logic.
    final isSignedIn = ref.watch(isSignedInProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final service = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects (Firestore Demo)'),
        actions: [
          // Sign out button
          if (isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await service.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Signed out')));
                }
              },
            ),
        ],
      ),
      body: !isSignedIn
          ? _buildSignInPrompt(context, service)
          : projectsAsync.when(
              data: (projects) => _buildProjectList(context, ref, projects),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(projectsStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: isSignedIn
          ? FloatingActionButton(
              onPressed: () => _showAddProjectDialog(context, service),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFirebaseUnavailable() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Firebase is not available on this platform.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Project sync features are disabled.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context, FirestoreService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Sign in to sync your projects',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await service.signInWithGoogle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed in successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
                }
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> projects,
  ) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Tap + to create your first project'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectTile(project: project);
      },
    );
  }

  Future<void> _showAddProjectDialog(
    BuildContext context,
    FirestoreService service,
  ) async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Project name',
            hintText: 'e.g., Launch new app',
          ),
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop();
              await service.addProject(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                try {
                  await service.addProject(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Created "$name"')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Individual project tile
class _ProjectTile extends ConsumerWidget {
  final dynamic project;

  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(firestoreServiceProvider);

    return ListTile(
      leading: Checkbox(
        value: project.isCompleted,
        onChanged: (value) async {
          await service.toggleProjectCompletion(
            project.id,
            project.isCompleted,
          );
        },
      ),
      title: Text(
        project.name,
        style: TextStyle(
          decoration: project.isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        'Created ${_formatDate(project.createdAt)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete project?'),
              content: Text('Delete "${project.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await service.deleteProject(project.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${project.name}"')),
              );
            }
          }
        },
      ),
      onTap: () => _showEditDialog(context, service, project),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    FirestoreService service,
    dynamic project,
  ) async {
    final controller = TextEditingController(text: project.name);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop();
              await service.updateProject(project.id, name: value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                await service.updateProject(project.id, name: name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
