import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/features/auth/login_form.dart';
import 'package:keystone/features/auth/mode_selection_screen.dart';
import 'package:keystone/features/help/help_screen.dart';
import 'package:keystone/providers/auth_provider.dart';
import 'package:keystone/providers/encryption_provider.dart';
import 'package:keystone/providers/settings_provider.dart';
import 'package:keystone/providers/theme_provider.dart';
import 'package:keystone/services/encryption_service.dart';
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
          // Google Calendar Sync Section
          if (kIsWeb) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Google Calendar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Builder(
              builder: (context) {
                final authState = ref.watch(authStateChangesProvider);
                final isSignedIn = authState.maybeWhen(
                  data: (user) => user != null,
                  orElse: () => false,
                );
                final syncEnabled = ref.watch(googleCalendarSyncProvider);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Sync Events to Google Calendar'),
                        subtitle: Text(
                          isSignedIn
                              ? 'Automatically sync your events to Google Calendar'
                              : 'Sign in with Google to enable calendar sync',
                        ),
                        secondary: const Icon(Icons.calendar_today),
                        value: syncEnabled && isSignedIn,
                        onChanged: isSignedIn
                            ? (value) {
                                ref
                                    .read(googleCalendarSyncProvider.notifier)
                                    .setEnabled(value);
                                if (value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Events will now sync to Google Calendar',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                      if (syncEnabled && isSignedIn)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'New and updated events will be synced to your Google Calendar',
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
          // Privacy & Encryption Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Privacy & Encryption',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const _EncryptionSettingsCard(),
          const Divider(),
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
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Documentation'),
              subtitle: const Text('Learn how to use Keystone'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
          ),
          ListTile(title: const Text('Version'), subtitle: Text(_version)),
        ],
      ),
    );
  }
}

/// Encryption Settings Card Widget
class _EncryptionSettingsCard extends ConsumerWidget {
  const _EncryptionSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encryptionEnabled = ref.watch(encryptionEnabledProvider);
    final encryptionService = ref.watch(encryptionServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('End-to-End Encryption'),
            subtitle: Text(
              encryptionEnabled
                  ? '🔒 Your data is encrypted on this device'
                  : '⚠️ Data is stored in plain text',
            ),
            secondary: Icon(
              encryptionEnabled ? Icons.lock : Icons.lock_open,
              color: encryptionEnabled ? Colors.green : Colors.orange,
            ),
            value: encryptionEnabled,
            onChanged: (value) async {
              if (value) {
                // Enabling encryption
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enable Encryption?'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This will encrypt all your data before syncing to the cloud.'),
                        SizedBox(height: 16),
                        Text('Benefits:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('• Complete privacy - even Google cannot read your data'),
                        Text('• Your encryption key stays on your device'),
                        Text('• Zero-knowledge architecture'),
                        SizedBox(height: 16),
                        Text('Important:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('• Backup your encryption key in case you lose your device'),
                        Text('• You can export it from the encryption settings'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Enable Encryption'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await ref.read(encryptionEnabledProvider.notifier).enableEncryption();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Encryption enabled! Future syncs will be encrypted.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error enabling encryption: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } else {
                // Disabling encryption
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Disable Encryption?'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ Warning: This will disable encryption for future syncs.'),
                        SizedBox(height: 16),
                        Text('Your previously encrypted cloud data will become unreadable!'),
                        SizedBox(height: 16),
                        Text('Are you sure you want to continue?'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Disable Encryption'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await ref.read(encryptionEnabledProvider.notifier).disableEncryption();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Encryption disabled'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error disabling encryption: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
          ),
          if (encryptionEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Export Encryption Key'),
              subtitle: const Text('Backup your key to restore data on another device'),
              trailing: const Icon(Icons.download),
              onTap: () async {
                try {
                  final key = await encryptionService.exportEncryptionKey();
                  if (key != null && context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Encryption Key'),
                        content: SelectableText(
                          key,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error exporting key: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Encryption Info'),
              subtitle: const Text('Learn about how your data is protected'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🔒 End-to-End Encryption'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'How It Works:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• All data is encrypted on YOUR device before syncing'),
                          Text('• Uses AES-256 encryption (military-grade)'),
                          Text('• Your encryption key never leaves your device'),
                          Text('• Google/Firebase can only see encrypted gibberish'),
                          SizedBox(height: 16),
                          Text(
                            'What Is Encrypted:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• Task titles and notes'),
                          Text('• Note titles and content'),
                          Text('• Journal entries'),
                          Text('• All tags and project names'),
                          SizedBox(height: 16),
                          Text(
                            'What Is NOT Encrypted:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• Dates and timestamps (needed for syncing)'),
                          Text('• Task status (pending/done/cancelled)'),
                          Text('• Data structure metadata'),
                          SizedBox(height: 16),
                          Text(
                            'Important:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          SizedBox(height: 8),
                          Text('⚠️ Export and save your encryption key!'),
                          Text('⚠️ If you lose your device and key, your data is unrecoverable'),
                          Text('✅ Keep your key in a password manager or secure location'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got It'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
