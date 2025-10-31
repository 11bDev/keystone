import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_sync_service.dart';
import 'firestore_provider.dart';

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync status data class
class SyncStatusData {
  final SyncStatus status;
  final String message;
  final DateTime? lastSyncTime;

  SyncStatusData({
    required this.status,
    required this.message,
    this.lastSyncTime,
  });

  SyncStatusData copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSyncTime,
  }) {
    return SyncStatusData(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Provider for Firestore sync service
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirestoreSyncService(firestoreService);
});

/// Provider to trigger full sync to Firestore (push)
final syncToFirestoreProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  await syncService.syncAllToFirestore();
});

/// Provider to pull data from Firestore
final pullFromFirestoreProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  await syncService.pullAllFromFirestore();
});

/// Provider for sync status
final syncStatusProvider = StateProvider<SyncStatusData>((ref) => SyncStatusData(
      status: SyncStatus.idle,
      message: 'Not synced',
    ));

/// Provider to handle automatic startup sync (pull from Firestore)
final startupSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  final statusNotifier = ref.read(syncStatusProvider.notifier);
  
  try {
    print('🔄 Starting automatic pull from Firestore...');
    statusNotifier.state = SyncStatusData(
      status: SyncStatus.syncing,
      message: 'Syncing from cloud...',
    );
    
    await syncService.pullAllFromFirestore();
    
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
