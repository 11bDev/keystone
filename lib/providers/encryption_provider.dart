import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/services/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the encryption service
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Provider to track if encryption is enabled in settings
final encryptionEnabledProvider = StateNotifierProvider<EncryptionEnabledNotifier, bool>((ref) {
  return EncryptionEnabledNotifier(ref.watch(encryptionServiceProvider));
});

/// Notifier to manage encryption enabled state
class EncryptionEnabledNotifier extends StateNotifier<bool> {
  final EncryptionService _encryptionService;

  EncryptionEnabledNotifier(this._encryptionService) : super(false) {
    _loadEncryptionStatus();
  }

  /// Load encryption status from service
  Future<void> _loadEncryptionStatus() async {
    final enabled = await _encryptionService.isEncryptionEnabled();
    state = enabled;
  }

  /// Enable encryption
  Future<void> enableEncryption() async {
    await _encryptionService.enableEncryption();
    await _encryptionService.initialize();
    state = true;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('encryption_enabled', true);
  }

  /// Disable encryption
  Future<void> disableEncryption() async {
    await _encryptionService.disableEncryption();
    state = false;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('encryption_enabled', false);
  }

  /// Refresh encryption status
  Future<void> refresh() async {
    await _loadEncryptionStatus();
  }
}

/// Provider to initialize encryption service on app startup
final encryptionInitializerProvider = FutureProvider<void>((ref) async {
  final encryptionService = ref.watch(encryptionServiceProvider);
  await encryptionService.initialize();
  
  // Trigger encryption enabled state check
  ref.read(encryptionEnabledProvider.notifier).refresh();
});
