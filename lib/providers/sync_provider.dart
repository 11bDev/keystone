import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:keystone/services/sync_service_interface.dart';
import 'package:keystone/services/sync_service_desktop.dart' as desktop;
import 'package:keystone/services/sync_service_mobile.dart' as mobile;
import 'package:keystone/models/sync_log_entry.dart';
import 'package:keystone/models/settings.dart' as app_settings;
import 'package:keystone/main.dart';

// Use mobile sync service on Android/iOS, desktop on others
final syncServiceProvider = Provider<SyncServiceInterface>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.SyncService();
  } else {
    return desktop.SyncService();
  }
});

// Provider to track if auto-sync is enabled (persisted in Hive)
final autoSyncEnabledProvider = StateNotifierProvider<AutoSyncNotifier, bool>((
  ref,
) {
  return AutoSyncNotifier();
});

class AutoSyncNotifier extends StateNotifier<bool> {
  static const String _key = 'auto_sync_enabled';
  Isar? _isar;

  AutoSyncNotifier() : super(false) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    _isar = await Isar.getInstance() ?? await _getIsarInstance();
    if (_isar == null) return;
    
    final setting = await _isar!.settings.filter().keyEqualTo(_key).findFirst();
    state = setting?.boolValue ?? false;
  }

  Future<Isar?> _getIsarInstance() async {
    try {
      return Isar.getInstance();
    } catch (e) {
      print('Error getting Isar instance: $e');
      return null;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (_isar == null) return;
    
    final setting = app_settings.Settings.createBool(_key, enabled);
    
    await _isar!.writeTxn(() async {
      // Delete existing setting first
      final existing = await _isar!.settings.filter().keyEqualTo(_key).findFirst();
      if (existing != null) {
        await _isar!.settings.delete(existing.id);
      }
      // Insert new setting
      await _isar!.settings.put(setting);
    });
    
    state = enabled;
  }
}

// Provider for sync log entries (last 24 hours)
final syncLogProvider = FutureProvider<List<SyncLogEntry>>((ref) async {
  final isar = await ref.read(isarProvider.future);
  final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

  final entries = await isar.syncLogEntrys
      .filter()
      .timestampGreaterThan(cutoffTime)
      .sortByTimestampDesc()
      .findAll();
      
  return entries;
});

// Provider to trigger background sync
final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
      return SyncNotifier(ref);
    });

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Log a sync event
  Future<void> _logSync(
    String type,
    bool success, [
    String? errorMessage,
  ]) async {
    try {
      final isar = await _ref.read(isarProvider.future);
      final entry = SyncLogEntry(
        timestamp: DateTime.now(),
        type: type,
        success: success,
        errorMessage: errorMessage,
      );
      
      await isar.writeTxn(() async {
        await isar.syncLogEntrys.put(entry);
      });

      // Clean up old entries (older than 24 hours)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final oldEntries = await isar.syncLogEntrys
          .filter()
          .timestampLessThan(cutoffTime)
          .findAll();
          
      if (oldEntries.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.syncLogEntrys.deleteAll(oldEntries.map((e) => e.id).toList());
        });
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

    print(
      'changeSync called - autoSyncEnabled: $autoSyncEnabled, isSignedIn: ${syncService.isSignedIn}',
    );

    if (!autoSyncEnabled || !syncService.isSignedIn) {
      print(
        'changeSync skipped - autoSync: $autoSyncEnabled, signedIn: ${syncService.isSignedIn}',
      );
      return;
    }

    // Don't update state to avoid UI flicker
    try {
      print('changeSync: Starting sync to Google Drive...');
      await syncService.syncToGoogleDrive();
      await _logSync('auto', true);
      print('changeSync: Sync completed successfully');
    } catch (error) {
      await _logSync('auto', false, error.toString());
      print('Change sync failed: $error');
    }
  }
}
