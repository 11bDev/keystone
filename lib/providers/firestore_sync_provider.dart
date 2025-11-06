import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/main.dart';
import 'package:keystone/providers/firestore_provider.dart';
import 'package:keystone/providers/journal_provider.dart';
import 'package:keystone/providers/note_provider.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:keystone/services/firestore_sync_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncStatusData {
  final SyncStatus status;
  final String message;
  final DateTime? lastSyncTime;

  SyncStatusData({
    required this.status,
    required this.message,
    this.lastSyncTime,
  });
}

class SyncStatusNotifier extends StateNotifier<SyncStatusData> {
  SyncStatusNotifier()
      : super(SyncStatusData(status: SyncStatus.idle, message: 'Not synced'));

  void setStatus(SyncStatus status, String message, {DateTime? syncTime}) {
    state = SyncStatusData(
      status: status,
      message: message,
      lastSyncTime: syncTime ?? state.lastSyncTime,
    );
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusData>((ref) {
  return SyncStatusNotifier();
});

/// Provider for Firestore sync service
final firestoreSyncServiceProvider = Provider<FirestoreSyncService?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final isar = ref.watch(isarProvider).asData?.value;

  if (isar != null && firestoreService != null) {
    return FirestoreSyncService(isar, firestoreService);
  }
  return null;
});

/// Provider to trigger full sync to Firestore (push)
final syncToFirestoreProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  if (syncService == null) throw Exception('Sync service not available');
  await syncService.syncAllToFirestore();
});

/// Provider to pull data from Firestore
final pullFromFirestoreProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  if (syncService == null) throw Exception('Sync service not available');

  await syncService.pullAllFromFirestore();

  // Invalidate providers to force UI to reload data from Isar
  ref.invalidate(taskListProvider);
  ref.invalidate(noteListProvider);
  ref.invalidate(journalEntryListProvider);
});

/// Provider to handle automatic startup sync (pull from Firestore)
final startupSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  final statusNotifier = ref.read(syncStatusProvider.notifier);

  if (syncService == null) {
    print('ℹ️ Skipping startup sync (Sync service not ready)');
    return;
  }

  try {
    print('🔄 Starting automatic pull from Firestore...');
    statusNotifier.state = SyncStatusData(
      status: SyncStatus.syncing,
      message: 'Syncing from cloud...',
    );

    await syncService.pullAllFromFirestore();

    // Invalidate providers to force UI to reload data from Isar
    ref.invalidate(taskListProvider);
    ref.invalidate(noteListProvider);
    ref.invalidate(journalEntryListProvider);

    statusNotifier.state = SyncStatusData(
      status: SyncStatus.success,
      message: 'Synced successfully',
      lastSyncTime: DateTime.now(),
    );
    print('✅ Automatic pull from Firestore completed');
  } catch (e) {
    print('⚠️ Automatic pull from Firestore failed: $e');
    // Don't update status to error on startup - user might be offline
    statusNotifier.state = SyncStatusData(
      status: SyncStatus.idle,
      message: 'Offline',
    );
  }
});

/// Provider to handle automatic startup sync (pull from Firestore) - temporarily disabled
// final startupSyncProvider = FutureProvider.autoDispose<void>((ref) async {
//   final syncService = ref.watch(firestoreSyncServiceProvider);
//   final statusNotifier = ref.read(syncStatusProvider.notifier);
//   
//   try {
//     print('🔄 Starting automatic pull from Firestore...');
//     statusNotifier.state = SyncStatusData(
//       status: SyncStatus.syncing,
//       message: 'Syncing from cloud...',
//     );
//     
//     await syncService.pullAllFromFirestore();
//     
//     statusNotifier.state = SyncStatusData(
//       status: SyncStatus.success,
//       message: 'Synced successfully',
//       lastSyncTime: DateTime.now(),
//     );
//     print('✅ Automatic pull from Firestore completed');
//   } catch (e) {
//     print('⚠️ Automatic pull from Firestore failed: $e');
//     // Don't update status to error on startup - user might be offline
//     statusNotifier.state = SyncStatusData(
//       status: SyncStatus.idle,
//       message: 'Offline',
//     );
//   }
// });
