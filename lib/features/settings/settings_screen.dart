import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/features/auth/login_form.dart';
import 'package:keystone/features/auth/mode_selection_screen.dart';
import 'package:keystone/providers/auth_provider.dart';
import 'package:keystone/providers/theme_provider.dart';
import 'package:keystone/widgets/app_navigation_actions.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          AppNavigationActions(currentRoute: '/settings'),
        ],
      ),
      body: ListView(
        children: [
          // Account Section
          if (kIsWeb) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: authState.when(
                data: (user) {
                  if (user != null) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Signed In'),
                      subtitle: Text(user.email ?? 'No email provided'),
                      trailing: TextButton(
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    );
                  }
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Not Signed In'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign In or Create an Account'),
                            content: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: const LoginForm(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              )
                            ],
                          ),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  );
                },
                loading: () => const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Authenticating...'),
                ),
                error: (err, stack) => ListTile(
                  leading: const Icon(Icons.error),
                  title: const Text('Authentication Error'),
                  subtitle: Text(err.toString()),
                ),
              ),
            ),
            const Divider(),
          ],
          // App Mode Section (Mobile only)
          if (!kIsWeb) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Data Storage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Builder(
              builder: (context) {
                final selectedMode = ref.watch(appModeProvider);
                final authState = ref.watch(authStateChangesProvider);
                final isSignedIn = authState.maybeWhen(
                  data: (user) => user != null,
                  orElse: () => false,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      RadioListTile<AppMode>(
                        title: const Text('Local Only'),
                        subtitle: const Text(
                          'Keep all data on this device only',
                        ),
                        secondary: const Icon(Icons.phone_android),
                        value: AppMode.localOnly,
                        groupValue: selectedMode,
                        onChanged: isSignedIn
                            ? null // Disable if signed in
                            : (value) {
                                if (value != null) {
                                  ref.read(appModeProvider.notifier).state = value;
                                }
                              },
                      ),
                      const Divider(height: 1),
                      RadioListTile<AppMode>(
                        title: const Text('Cloud Sync'),
                        subtitle: Text(
                          isSignedIn
                              ? 'Currently syncing with cloud'
                              : 'Sign in to sync across devices',
                        ),
                        secondary: const Icon(Icons.cloud),
                        value: AppMode.cloudSync,
                        groupValue: selectedMode,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(appModeProvider.notifier).state = value;
                            // If not signed in, show login dialog
                            if (!isSignedIn) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Sign In Required'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'To use Cloud Sync, you need to sign in with your account.',
                                      ),
                                      SizedBox(height: 16),
                                      LoginForm(),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        // Switch back to local only
                                        ref.read(appModeProvider.notifier).state =
                                            AppMode.localOnly;
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (selectedMode == AppMode.localOnly && !isSignedIn)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your data is stored only on this device',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (selectedMode == AppMode.cloudSync && isSignedIn)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your data is automatically synced to the cloud',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
          ],
          // Theme Selection
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                RadioListTile<AppTheme>(
                  title: const Text('Light Theme'),
                  subtitle: const Text('Clean and bright'),
                  secondary: const Icon(Icons.light_mode),
                  value: AppTheme.light,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppTheme>(
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Easy on the eyes'),
                  secondary: const Icon(Icons.dark_mode),
                  value: AppTheme.dark,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppTheme>(
                  title: const Text('Sepia Theme'),
                  subtitle: const Text('Aged parchment look'),
                  secondary: const Icon(Icons.auto_stories),
                  value: AppTheme.sepia,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppTheme>(
                  title: const Text('Parchment Theme'),
                  subtitle: const Text(
                    'Beautiful serif fonts for reading & writing',
                  ),
                  secondary: const Icon(Icons.menu_book),
                  value: AppTheme.parchment,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AppTheme>(
                  title: const Text('Newspaper Theme'),
                  subtitle: const Text(
                    'Classic newsprint with bold serif typography',
                  ),
                  secondary: const Icon(Icons.article),
                  value: AppTheme.newspaper,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Tags Documentation
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tags',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keystone supports two types of tags to organize your content:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Hashtags section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tag,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hashtags (#)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Use hashtags for general categorization and quick filtering.',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Examples: #work #personal #important #urgent',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Project tags section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_tree,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Project Tags (-)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Use project tags to link tasks, notes, and journal entries to specific projects.',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Examples: -website -mobile-app -research',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Create projects in the Projects screen to organize related items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Tips:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTip('You can use multiple tags in a single item'),
                  _buildTip('Tags are case-insensitive (#Work and #work are the same)'),
                  _buildTip('Use the Search feature to find items by tags'),
                  _buildTip('Project tags automatically link to your Projects'),
                ],
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(title: const Text('Version'), subtitle: Text(_version)),
        ],
      ),
    );
  }
}
