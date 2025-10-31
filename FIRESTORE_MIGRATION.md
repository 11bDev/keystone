# Firebase Firestore Migration Guide

This guide explains the migration from Google Drive sync to Cloud Firestore for offline-first synchronization.

## Overview

**Before (Google Drive):**
- Manual sync operations (upload/download)
- Limited offline support
- File-based storage (JSON)
- Complex conflict resolution

**After (Firestore):**
- Automatic real-time sync
- Full offline persistence (automatic)
- Document-based NoSQL database
- Built-in conflict resolution

## Architecture Changes

### Data Flow Comparison

#### Old (Google Drive + Hive):
```
User Action → Hive (local) → Manual Sync → Google Drive → Other Devices
                ↓
           Local UI Update
```

#### New (Firestore):
```
User Action → Firestore SDK → Local Cache (automatic) → Server (when online) → Other Devices (real-time)
                                      ↓
                              Local UI Update (instant)
```

### Key Benefits

1. **Offline-First**: Firestore SDK handles offline/online automatically
2. **Real-Time**: Changes sync instantly when online (no manual sync button)
3. **Conflict Resolution**: Firestore handles conflicts automatically
4. **Simpler Code**: No manual upload/download logic needed
5. **Better UX**: Optimistic updates feel instant

## Implementation Status

### ✅ Completed (Basic Infrastructure)

1. **Dependencies Added** (`pubspec.yaml`):
   ```yaml
   firebase_core: ^3.7.1
   cloud_firestore: ^5.5.0
   firebase_auth: ^5.3.3
   ```

2. **Project Model** (`lib/models/project.dart`):
   - Simple demonstration model
   - Firestore serialization methods
   - Shows offline-first pattern

3. **Firestore Service** (`lib/services/firestore_service.dart`):
   - User-scoped data (`users/{userId}/projects`)
   - Stream-based API for real-time updates
   - Offline-ready CRUD operations

4. **Riverpod Providers** (`lib/providers/firestore_provider.dart`):
   - `projectsStreamProvider`: Real-time project list
   - `authStateProvider`: Firebase Auth state
   - `isSignedInProvider`: User sign-in status

5. **Example UI** (`lib/features/projects/projects_example_screen.dart`):
   - Demonstrates real-time streams
   - Shows offline capability
   - Sign-in/sign-out flow

6. **Setup Guide** (`FIREBASE_SETUP.md`):
   - Step-by-step Firebase Console setup
   - Android and Desktop configuration
   - Security rules for production

### ⏳ Pending (Full Migration)

1. **Firebase Initialization** (`lib/main.dart`):
   - Add `Firebase.initializeApp()`
   - Enable Firestore offline persistence globally
   - Configure cache settings

2. **Firebase Configuration** (`lib/firebase_options.dart`):
   - Platform-specific Firebase config
   - API keys from Firebase Console
   - Auto-generated via FlutterFire CLI (recommended)

3. **Google Sign-In Integration**:
   - Update `FirestoreService.signInWithGoogle()`
   - Integrate with existing `google_sign_in` package
   - Link Google Auth with Firebase Auth

4. **Migrate Existing Models**:
   - Task model → Firestore
   - Note model → Firestore
   - JournalEntry model → Firestore

5. **Data Migration**:
   - One-time migration from Hive to Firestore
   - Optional: Keep Hive as backup during transition
   - Migration UI for user to trigger

6. **Update Providers**:
   - Replace manual sync providers with Firestore streams
   - Remove Google Drive service dependencies
   - Update UI to use StreamProvider

7. **Security Rules**:
   - Production Firestore rules (per-user access)
   - Test rules before production release
   - Add admin/backup access if needed

## Step-by-Step Migration Plan

### Phase 1: Firebase Setup (DO THIS FIRST)

**Estimated Time**: 30 minutes

1. Follow `FIREBASE_SETUP.md` to create Firebase project
2. Add Android app with `google-services.json`
3. Add Web app for Desktop (copy config)
4. Enable Firestore Database (test mode)
5. Enable Google Authentication

**Validation**:
```bash
# Check if google-services.json exists
ls -la android/app/google-services.json

# Should show the file
```

### Phase 2: Initialize Firebase in App

**File**: `lib/firebase_options.dart` (CREATE THIS)

**Option A - FlutterFire CLI (Recommended)**:
```bash
# Install CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=keystone-app
```

This auto-generates `firebase_options.dart` with your config.

**Option B - Manual**:
Copy the template from `FIREBASE_SETUP.md` and fill in your values from Firebase Console.

---

**File**: `lib/main.dart` (UPDATE)

Add Firebase initialization:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firestore for offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Initialize Hive (keep during transition)
  await Hive.initFlutter();
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Note>('notes');
  await Hive.openBox<JournalEntry>('journal_entries');
  await Hive.openBox('sync_log');
  await Hive.openBox('settings');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

**Validation**:
```bash
flutter run -d linux
# Should see "Firebase initialized" in logs
# No errors about Firebase
```

### Phase 3: Test with Projects Example

**Add to Navigation** (e.g., in `lib/main.dart` or settings):

```dart
// Add a debug button to test Firestore
ListTile(
  leading: const Icon(Icons.science),
  title: const Text('Test Firestore (Projects)'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProjectsExampleScreen(),
      ),
    );
  },
),
```

**Test Offline Mode**:

1. Run app
2. Sign in with Google
3. Add a project
4. Turn off WiFi
5. Add another project (works offline!)
6. Turn on WiFi
7. Check Firebase Console → Data syncs automatically

### Phase 4: Migrate Task Model

**File**: `lib/models/task.dart` (UPDATE)

Add Firestore methods:

```dart
class Task extends HiveObject {
  // ... existing Hive fields ...
  
  String? firestoreId; // NEW: Firestore document ID
  
  // NEW: Convert from Firestore
  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      id: data['localId'] as int, // Keep Hive ID for compatibility
      title: data['title'] as String,
      description: data['description'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] as bool,
      category: data['category'] as String?,
      priority: data['priority'] as String?,
    )..firestoreId = doc.id;
  }
  
  // NEW: Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'localId': id,
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'category': category,
      'priority': priority,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
```

**File**: `lib/services/firestore_service.dart` (UPDATE)

Add Task methods (similar to Projects):

```dart
// Stream all tasks for current user
Stream<List<Task>> streamTasks() {
  if (!isSignedIn) return Stream.value([]);
  
  return _firestore
      .collection('users')
      .doc(_userId)
      .collection('tasks')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc))
        .toList();
  });
}

Future<void> addTask(Task task) async {
  if (!isSignedIn) throw Exception('Must be signed in');
  
  await _firestore
      .collection('users')
      .doc(_userId)
      .collection('tasks')
      .add(task.toFirestore());
}

Future<void> updateTask(String firestoreId, Map<String, dynamic> updates) async {
  if (!isSignedIn) throw Exception('Must be signed in');
  
  updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
  
  await _firestore
      .collection('users')
      .doc(_userId)
      .collection('tasks')
      .doc(firestoreId)
      .update(updates);
}

Future<void> deleteTask(String firestoreId) async {
  if (!isSignedIn) throw Exception('Must be signed in');
  
  await _firestore
      .collection('users')
      .doc(_userId)
      .collection('tasks')
      .doc(firestoreId)
      .delete();
}
```

**File**: `lib/providers/task_provider.dart` (UPDATE)

Replace Hive provider with Firestore stream:

```dart
// OLD (Hive):
final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

// NEW (Firestore):
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.streamTasks();
});

// For UI compatibility, create a computed provider:
final tasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  return tasksAsync.when(
    data: (tasks) => tasks,
    loading: () => [],
    error: (_, __) => [],
  );
});
```

**Update UI** (`lib/features/tasks/...`):

```dart
// OLD:
final tasks = ref.watch(tasksProvider);

// NEW (if using StreamProvider directly):
final tasksAsync = ref.watch(tasksStreamProvider);

return tasksAsync.when(
  data: (tasks) => _buildTaskList(tasks),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);

// OR (if using computed provider):
final tasks = ref.watch(tasksProvider); // Same as before!
```

### Phase 5: Data Migration Script

**File**: `lib/services/migration_service.dart` (CREATE)

```dart
class MigrationService {
  final FirestoreService _firestore;
  final Box<Task> _taskBox;
  
  MigrationService(this._firestore, this._taskBox);
  
  /// Migrate all Hive tasks to Firestore (one-time)
  Future<void> migrateTasks() async {
    final hiveTasks = _taskBox.values.toList();
    
    for (final task in hiveTasks) {
      try {
        await _firestore.addTask(task);
        print('Migrated task: ${task.title}');
      } catch (e) {
        print('Failed to migrate task ${task.title}: $e');
      }
    }
    
    print('Migration complete: ${hiveTasks.length} tasks');
  }
  
  /// Check if migration is needed
  Future<bool> needsMigration() async {
    // Check if Firestore is empty but Hive has data
    final firestoreTasks = await _firestore.streamTasks().first;
    final hiveTasks = _taskBox.values.toList();
    
    return firestoreTasks.isEmpty && hiveTasks.isNotEmpty;
  }
}
```

**Show Migration Dialog** (in `lib/main.dart` or first screen):

```dart
final needsMigration = await migrationService.needsMigration();

if (needsMigration && isSignedIn) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Migrate to Cloud Sync?'),
      content: const Text(
        'Keystone now uses Cloud Firestore for better offline sync.\n\n'
        'Would you like to migrate your existing data?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await migrationService.migrateTasks();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Migration complete!')),
            );
          },
          child: const Text('Migrate Now'),
        ),
      ],
    ),
  );
}
```

### Phase 6: Repeat for Notes & Journal Entries

Follow the same pattern as Tasks:

1. Add `fromFirestore()` and `toFirestore()` to model
2. Add stream/CRUD methods to `FirestoreService`
3. Create `StreamProvider` in providers
4. Update UI to use streams
5. Add to migration service

### Phase 7: Remove Google Drive Code (Optional)

Once Firestore is fully working:

1. Remove `lib/services/sync_service_*.dart`
2. Remove `lib/providers/sync_provider.dart` (old Google Drive sync)
3. Remove Google Drive dependencies from `pubspec.yaml`:
   ```yaml
   # REMOVE THESE:
   # googleapis: ^15.0.0
   # googleapis_auth: ^2.0.0
   ```
4. Update settings screen to remove manual sync button
5. Remove sync log feature (Firestore syncs automatically)

**OR Keep as Backup**:
- Keep Google Drive sync as export/backup feature
- Rename to "Export to Google Drive" instead of "Sync"
- Use for data portability

### Phase 8: Production Security Rules

**Firebase Console → Firestore → Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function: Check if user owns the data
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if isOwner(userId);
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Test Security Rules**:

1. Firebase Console → Firestore → Rules → Rules Playground
2. Simulate read/write as authenticated user
3. Simulate read/write as different user (should fail)
4. Publish rules

## Testing Checklist

### Before Migration
- [ ] Firebase project created
- [ ] Android app configured (`google-services.json`)
- [ ] Desktop app configured (`firebase_options.dart`)
- [ ] Firestore database enabled
- [ ] Google authentication enabled
- [ ] Firebase initialized in app (no errors)

### After Migration
- [ ] Can sign in with Google
- [ ] Can create/read/update/delete data
- [ ] Data syncs between devices in real-time
- [ ] Offline mode works (airplane mode test)
- [ ] Data persists after app restart (offline)
- [ ] Data syncs when back online
- [ ] Security rules prevent unauthorized access
- [ ] Old Hive data migrated successfully

### Performance Testing
- [ ] App starts quickly (Firebase doesn't slow down startup)
- [ ] UI feels instant (optimistic updates)
- [ ] Works with 100+ items without lag
- [ ] Network usage is reasonable
- [ ] Battery usage is acceptable

## Rollback Plan

If migration fails:

1. **Keep Hive**: Don't delete Hive data during migration
2. **Feature Flag**: Add a setting to switch between Hive and Firestore
3. **Git Revert**: All changes are in git history
4. **User Data**: Firestore doesn't delete on uninstall (can recover)

## Future Enhancements

Once Firestore is working:

1. **Real-Time Collaboration**: Multiple users on same project
2. **Cloud Functions**: Server-side triggers (e.g., send notifications)
3. **Backup/Restore**: Export to JSON from Firestore
4. **Analytics**: Firebase Analytics integration
5. **Crashlytics**: Automatic crash reporting
6. **Remote Config**: Toggle features without app update

## Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Offline Data](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [FlutterFire](https://firebase.flutter.dev/)

## Support

Issues? Check:
1. `FIREBASE_SETUP.md` for configuration
2. Firebase Console → Project Settings → Apps
3. Flutter logs: `flutter run -v`
4. Firestore Console → Data tab (verify writes)

---

**Next Steps**: Follow Phase 1 → Phase 2 → Phase 3 to test basic Firestore functionality before migrating existing models.
