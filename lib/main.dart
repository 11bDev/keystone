import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:keystone/features/calendar/calendar_screen.dart';
import 'package:keystone/features/journal/journal_tab.dart';
import 'package:keystone/features/notes/notes_tab.dart';
import 'package:keystone/features/tasks/tasks_tab.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/sync_log_entry.dart';
import 'package:keystone/features/search/search_screen.dart';
import 'package:keystone/features/settings/settings_screen.dart';
import 'package:keystone/providers/theme_provider.dart';
import 'package:keystone/providers/sync_provider.dart';
import 'package:keystone/providers/firestore_sync_provider.dart';
import 'package:keystone/services/notification_service.dart';

final notificationService = NotificationService();

/// Provider to track if Firebase was successfully initialized.
final isFirebaseAvailableProvider = StateProvider<bool>((ref) => false);

/// Provider to handle asynchronous Firebase initialization.
final firebaseInitializerProvider = FutureProvider<FirebaseApp?>((ref) async {
  try {
    // This will fail on platforms where the platform channel isn't available (e.g., Linux).
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    return app;
  } catch (e) {
    // Firebase initialization failed - this is expected on unsupported platforms like Linux
    print('⚠️ Firebase initialization failed: $e');
    print('ℹ️ App will run in local-only mode');
    return null;
  }
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await notificationService.init();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(SyncLogEntryAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Note>('notes');
  await Hive.openBox<JournalEntry>('journal_entries');
  await Hive.openBox<SyncLogEntry>('sync_log');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseInitialization = ref.watch(firebaseInitializerProvider);
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Keystone',
      theme: AppThemes.getTheme(currentTheme),
      home: firebaseInitialization.when(
        data: (firebaseApp) {
          if (firebaseApp != null) {
            // Firebase initialized successfully.
            FirebaseFirestore.instance.settings = const Settings(
              persistenceEnabled: true,
              cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
            );
            print('✅ Firestore configured for offline persistence');
            // Set the flag to true, allowing Firebase-dependent UI to build.
            Future.microtask(() => ref.read(isFirebaseAvailableProvider.notifier).state = true);
          } else {
            // Firebase initialization returned null (failed gracefully)
            print('ℹ️ Running in local-only mode (Firebase unavailable)');
          }
          return const MainScreenWrapper();
        },
        loading: () => const SplashScreen(message: 'Initializing...'),
        error: (error, stackTrace) {
          // Firebase failed to initialize with an error. The app will run without Firebase features.
          print('⚠️ Firebase initialization error: $error');
          // The flag remains false.
          return const MainScreenWrapper();
        },
      ),
    );
  }
}

/// A simple splash screen to show during initialization.
class SplashScreen extends StatelessWidget {
  final String message;
  const SplashScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}

/// This widget wraps the main screen and its startup logic.
/// It's called after Firebase initialization is handled.
class MainScreenWrapper extends ConsumerStatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  ConsumerState<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends ConsumerState<MainScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger startup sync operations after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Google Drive sync (legacy)
      ref.read(syncNotifierProvider.notifier).startupSync();
      
      // Firestore sync - only if Firebase is available
      final isFirebaseAvailable = ref.read(isFirebaseAvailableProvider);
      if (isFirebaseAvailable) {
        ref.read(startupSyncProvider);
      } else {
        print('ℹ️ Skipping Firestore sync (Firebase unavailable on this platform)');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSyncStatusIcon(SyncStatusData status) {
    IconData icon;
    Color color;
    String tooltip;
    
    switch (status.status) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.success:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = status.lastSyncTime != null
            ? 'Synced ${_formatSyncTime(status.lastSyncTime!)}'
            : 'Synced';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = status.message;
        break;
      case SyncStatus.idle:
        icon = Icons.cloud_outlined;
        color = Colors.grey;
        tooltip = 'Not synced';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 18,
        color: color,
      ),
    );
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Keystone'),
            const SizedBox(width: 12),
            _buildSyncStatusIcon(syncStatus),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Notes'),
            Tab(text: 'Journal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [TasksTab(), NotesTab(), JournalTab()],
      ),
    );
  }
}
