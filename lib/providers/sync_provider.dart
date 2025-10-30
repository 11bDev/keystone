import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/services/sync_service_interface.dart';
import 'package:keystone/services/sync_service_desktop.dart' as desktop;
import 'package:keystone/services/sync_service_mobile.dart' as mobile;
import 'package:keystone/models/sync_log_entry.dart';

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

// Provider for sync log entries (last 24 hours)
final syncLogProvider = Provider<List<SyncLogEntry>>((ref) {
  final box = Hive.box<SyncLogEntry>('sync_log');
  final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
  
  return box.values
      .where((entry) => entry.timestamp.isAfter(cutoffTime))
      .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

// Provider to trigger background sync
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  SyncNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Log a sync event
  Future<void> _logSync(String type, bool success, [String? errorMessage]) async {
    try {
      final box = Hive.box<SyncLogEntry>('sync_log');
      final entry = SyncLogEntry(
        timestamp: DateTime.now(),
        type: type,
        success: success,
        errorMessage: errorMessage,
      );
      await box.add(entry);
      
      // Clean up old entries (older than 24 hours)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final keysToDelete = <dynamic>[];
      for (var i = 0; i < box.length; i++) {
        final entry = box.getAt(i);
        if (entry != null && entry.timestamp.isBefore(cutoffTime)) {
          keysToDelete.add(box.keyAt(i));
        }
      }
      for (var key in keysToDelete) {
        await box.delete(key);
      }
    } catch (e) {
      print('Error logging sync: $e');
    }
  }

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
      await _logSync('auto', true);
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      await _logSync('auto', false, error.toString());
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
      await _logSync('manual', true);
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      await _logSync('manual', false, error.toString());
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Sync on app startup
  Future<void> startupSync() async {
    final syncService = _ref.read(syncServiceProvider);
    final autoSyncEnabled = _ref.read(autoSyncEnabledProvider);
    
    if (!autoSyncEnabled || !syncService.isSignedIn) {
      return;
    }

    state = const AsyncValue.loading();
    try {
      await syncService.syncToGoogleDrive();
      await _logSync('startup', true);
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      await _logSync('startup', false, error.toString());
      state = AsyncValue.error(error, stack);
      print('Startup sync failed: $error');
    }
  }

  /// Sync on data change
  Future<void> changeSync() async {
    final syncService = _ref.read(syncServiceProvider);
    final autoSyncEnabled = _ref.read(autoSyncEnabledProvider);
    
    if (!autoSyncEnabled || !syncService.isSignedIn) {
      return;
    }

    // Don't update state to avoid UI flicker
    try {
      await syncService.syncToGoogleDrive();
      await _logSync('auto', true);
    } catch (error) {
      await _logSync('auto', false, error.toString());
      print('Change sync failed: $error');
    }
  }
}
