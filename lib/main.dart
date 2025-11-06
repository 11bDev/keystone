import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keystone/features/landing/landing_page.dart';
import 'package:keystone/features/auth/mode_selection_screen.dart';
import 'package:keystone/providers/auth_provider.dart';
import 'firebase_options.dart';
import 'package:keystone/features/calendar/calendar_screen.dart';
import 'package:keystone/features/journal/journal_tab.dart';
import 'package:keystone/features/notes/notes_tab.dart';
import 'package:keystone/features/tasks/tasks_tab.dart';
import 'package:keystone/features/projects/projects_screen.dart';
import 'package:keystone/features/search/search_screen.dart';
import 'package:keystone/features/settings/settings_screen.dart';
import 'package:keystone/features/lists/lists_screen.dart';
import 'package:keystone/providers/theme_provider.dart';
import 'package:keystone/services/notification_service.dart';
import 'package:keystone/widgets/app_navigation_actions.dart';

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

  // Initialize notification service
  await notificationService.init();

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
          return AuthWrapper();
        },
        loading: () => const SplashScreen(message: 'Initializing...'),
        error: (error, stackTrace) {
          // Firebase failed to initialize with an error. The app will run without Firebase features.
          print('⚠️ Firebase initialization error: $error');
          // The flag remains false.
          return AuthWrapper();
        },
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final selectedMode = ref.watch(appModeProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated - go to main app
          return const MainScreenWrapper();
        } else {
          // User is not authenticated
          // On web, always show landing page
          if (kIsWeb) {
            return const LandingPage();
          } else {
            // On mobile, check if user has selected a mode
            if (selectedMode == null) {
              // No mode selected yet - show selection screen
              return const ModeSelectionScreen();
            } else if (selectedMode == AppMode.localOnly) {
              // Local only mode - go directly to app without auth
              return const MainScreenWrapper();
            } else {
              // Cloud sync mode - show landing page for authentication
              return const LandingPage();
            }
          }
        }
      },
      loading: () => const SplashScreen(message: 'Authenticating...'),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication Error: $error'),
        ),
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
      // Firestore sync
      final isFirebaseAvailable = ref.read(isFirebaseAvailableProvider);
      if (isFirebaseAvailable) {
        // ref.read(startupSyncProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Keystone'),
          ],
        ),
        actions: const [
          AppNavigationActions(),
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
