import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/providers/sync_provider.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:keystone/providers/note_provider.dart';
import 'package:keystone/providers/journal_provider.dart';
import 'package:keystone/providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  DateTime? _lastBackupTime;
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadBackupTime();
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

  Future<void> _loadBackupTime() async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService.isSignedIn) {
      final time = await syncService.getLastBackupTime();
      if (mounted) {
        setState(() {
          _lastBackupTime = time;
        });
      }
    }
  }

  /// Refresh all providers to reload data from Hive after sync
  void _refreshAllProviders() {
    // Reload data from Hive boxes
    ref.read(taskListProvider.notifier).reload();
    ref.read(noteListProvider.notifier).reload();
    ref.read(journalEntryListProvider.notifier).reload();
  }

  Future<void> _signIn() async {
    final syncService = ref.read(syncServiceProvider);

    try {
      final success = await syncService.signIn();

      if (success && mounted) {
        // Enable auto-sync
        ref.read(autoSyncEnabledProvider.notifier).state = true;
        
        setState(() {});
        _loadBackupTime();
        
        // Check if a backup exists on Google Drive
        final backupExists = await _checkIfBackupExists();
        
        if (backupExists && mounted) {
          // Ask user what to do with existing backup
          final shouldRestore = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Existing Backup Found'),
              content: const Text(
                'We found an existing backup on Google Drive. '
                'Would you like to restore your data from this backup, '
                'or start fresh and overwrite it with your current data?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Start Fresh'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Restore Backup'),
                ),
              ],
            ),
          );

          if (mounted) {
            try {
              if (shouldRestore == true) {
                // Restore from backup
                await syncService.syncFromGoogleDrive();
                _refreshAllProviders(); // Refresh UI with restored data
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data restored from backup as ${syncService.userEmail}')),
                );
              } else {
                // Upload current data
                await syncService.syncToGoogleDrive();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Signed in and uploaded current data as ${syncService.userEmail}')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            }
          }
        } else if (mounted) {
          // No backup exists, upload current data
          try {
            await syncService.syncToGoogleDrive();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signed in and created backup as ${syncService.userEmail}')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signed in as ${syncService.userEmail} (backup creation failed: $e)')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to sign in')));
      }
    } catch (e) {
      if (mounted) {
        // Show helpful error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Drive Setup Required'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To use Google Drive sync, you need to set up OAuth credentials first.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Quick Setup:'),
                  const SizedBox(height: 8),
                  const Text('1. Go to console.cloud.google.com'),
                  const Text('2. Create a project'),
                  const Text('3. Enable Google Drive API'),
                  const Text('4. Create OAuth 2.0 Desktop credentials'),
                  const Text('5. Update credentials in code'),
                  const SizedBox(height: 16),
                  const Text(
                    'OR use Local Backup below (no setup required!).',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'See SYNC_WORKING.md for detailed instructions.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<bool> _checkIfBackupExists() async {
    final syncService = ref.read(syncServiceProvider);
    try {
      final lastBackupTime = await syncService.getLastBackupTime();
      return lastBackupTime != null;
    } catch (e) {
      print('Error checking for backup: $e');
      return false;
    }
  }

  Future<void> _signOut() async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.signOut();
    
    // Disable auto-sync
    ref.read(autoSyncEnabledProvider.notifier).state = false;
    
    if (mounted) {
      setState(() {
        _lastBackupTime = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out')));
    }
  }

  Future<void> _backup() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncToGoogleDrive();

      if (mounted) {
        _loadBackupTime();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace all your current data with the backup from Google Drive. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncFromGoogleDrive();

      // Refresh all providers by reloading data
      ref.read(taskListProvider.notifier).reload();
      ref.read(noteListProvider.notifier).reload();
      ref.read(journalEntryListProvider.notifier).reload();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restore successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _exportLocal() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      final filePath = await syncService.exportToLocalFile();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to:\n$filePath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _importLocal() async {
    // Pick a file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from File'),
        content: const Text(
          'This will replace all your current data with the data from the selected file. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.importFromLocalFile(result.files.single.path!);

      // Refresh all providers
      ref.read(taskListProvider.notifier).reload();
      ref.read(noteListProvider.notifier).reload();
      ref.read(journalEntryListProvider.notifier).reload();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncService = ref.watch(syncServiceProvider);
    final isSignedIn = syncService.isSignedIn;
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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
                  subtitle: const Text('Beautiful serif fonts for reading & writing'),
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
                  subtitle: const Text('Classic newsprint with bold serif typography'),
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
          const SizedBox(height: 24),
          // Highlight local backup first - no setup needed!
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Local Backup (No Setup Required)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.shade900.withOpacity(0.3)
                : Colors.green.shade50,
            child: Column(
              children: [
                ListTile(
                  enabled: !_isSyncing,
                  leading: const Icon(Icons.file_download, color: Colors.green),
                  title: const Text('Export to File'),
                  subtitle: const Text(
                    'Save data as JSON file (works offline)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _exportLocal,
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: !_isSyncing,
                  leading: const Icon(Icons.file_upload, color: Colors.green),
                  title: const Text('Import from File'),
                  subtitle: const Text('Load data from JSON file'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _importLocal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Google Drive Sync (Setup Required)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isSignedIn)
            ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text('Google Drive'),
              subtitle: const Text('Not connected'),
              trailing: ElevatedButton(
                onPressed: _signIn,
                child: const Text('Sign In'),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: const Text('Google Drive'),
              subtitle: Text('Signed in as ${syncService.userEmail}'),
              trailing: TextButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            ),
            if (_lastBackupTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Last backup: ${_formatDateTime(_lastBackupTime!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const Divider(),
            // Auto-sync toggle
            SwitchListTile(
              secondary: const Icon(Icons.sync),
              title: const Text('Auto-sync'),
              subtitle: const Text('Automatically sync changes to Google Drive'),
              value: ref.watch(autoSyncEnabledProvider),
              onChanged: (value) {
                ref.read(autoSyncEnabledProvider.notifier).state = value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Auto-sync enabled' : 'Auto-sync disabled'),
                  ),
                );
              },
            ),
            const Divider(),
            // Sync log viewer
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Sync Log'),
              subtitle: const Text('View recent sync activity (last 24 hours)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SyncLogScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              enabled: !_isSyncing,
              leading: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              title: const Text('Backup to Google Drive'),
              subtitle: const Text('Manually save your data to the cloud'),
              onTap: _backup,
            ),
            ListTile(
              enabled: !_isSyncing,
              leading: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download),
              title: const Text('Restore from Google Drive'),
              subtitle: const Text('Replace local data with backup'),
              onTap: _restore,
            ),
          ],
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: Text(_version),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

// Sync Log Screen
class SyncLogScreen extends ConsumerWidget {
  const SyncLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncLog = ref.watch(syncLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Log'),
      ),
      body: syncLog.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sync activity yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sync logs will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: syncLog.length,
              itemBuilder: (context, index) {
                final entry = syncLog[index];
                return ListTile(
                  leading: Icon(
                    entry.success ? Icons.check_circle : Icons.error,
                    color: entry.success ? Colors.green : Colors.red,
                  ),
                  title: Text(entry.displayType),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatLogTime(entry.timestamp)),
                      if (!entry.success && entry.errorMessage != null)
                        Text(
                          entry.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Text(
                    _formatLogTimestamp(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatLogTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatLogTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
