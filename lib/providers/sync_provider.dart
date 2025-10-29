import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/services/sync_service_interface.dart';
import 'package:keystone/services/sync_service_desktop.dart' as desktop;
import 'package:keystone/services/sync_service_mobile.dart' as mobile;

// Use mobile sync service on Android/iOS, desktop on others
final syncServiceProvider = Provider<SyncServiceInterface>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.SyncService();
  } else {
    return desktop.SyncService();
  }
});

// Provider to track if auto-sync is enabled
final autoSyncEnabledProvider = StateProvider<bool>((ref) => false);

// Provider to trigger background sync
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  SyncNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Trigger auto-sync if enabled and signed in
  Future<void> autoSync() async {
    final syncService = _ref.read(syncServiceProvider);
    final autoSyncEnabled = _ref.read(autoSyncEnabledProvider);
    
    if (!autoSyncEnabled || !syncService.isSignedIn) {
      return;
    }

    state = const AsyncValue.loading();
    try {
      await syncService.syncToGoogleDrive();
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      // Don't show errors for background sync - just log
      print('Background sync failed: $error');
    }
  }

  /// Manual sync (always runs if signed in)
  Future<void> manualSync() async {
    final syncService = _ref.read(syncServiceProvider);
    
    if (!syncService.isSignedIn) {
      throw Exception('Not signed in to Google Drive');
    }

    state = const AsyncValue.loading();
    try {
      await syncService.syncToGoogleDrive();
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}
