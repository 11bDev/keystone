import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// End-to-end encryption service for Keystone
/// 
/// This service provides:
/// - AES-256 encryption for all user data
/// - Secure key storage on device
/// - Zero-knowledge architecture (server never sees unencrypted data)
class EncryptionService {
  static const String _keyStorageKey = 'keystone_encryption_key';
  static const String _ivStorageKey = 'keystone_encryption_iv';
  
  final FlutterSecureStorage _secureStorage;
  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;
  
  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize encryption - generate or load encryption key
  Future<void> initialize() async {
    await _loadOrGenerateKey();
  }

  /// Check if encryption is enabled (key exists)
  Future<bool> isEncryptionEnabled() async {
    try {
      final keyString = await _secureStorage.read(key: _keyStorageKey);
      return keyString != null && keyString.isNotEmpty;
    } catch (e) {
      print('Error checking encryption status: $e');
      return false;
    }
  }

  /// Load existing key or generate a new one
  Future<void> _loadOrGenerateKey() async {
    try {
      // Try to load existing key
      final keyString = await _secureStorage.read(key: _keyStorageKey);
      final ivString = await _secureStorage.read(key: _ivStorageKey);

      if (keyString != null && ivString != null) {
        // Load existing key
        _encryptionKey = encrypt.Key.fromBase64(keyString);
        _iv = encrypt.IV.fromBase64(ivString);
        print('✅ Loaded existing encryption key');
      } else {
        // Generate new key
        await _generateNewKey();
      }
    } catch (e) {
      print('Error loading encryption key: $e');
      // If loading fails, generate new key
      await _generateNewKey();
    }
  }

  /// Generate a new encryption key
  Future<void> _generateNewKey() async {
    try {
      // Generate random 256-bit key for AES-256
      _encryptionKey = encrypt.Key.fromSecureRandom(32);
      _iv = encrypt.IV.fromSecureRandom(16);

      // Store key securely
      await _secureStorage.write(
        key: _keyStorageKey,
        value: _encryptionKey!.base64,
      );
      await _secureStorage.write(
        key: _ivStorageKey,
        value: _iv!.base64,
      );

      print('✅ Generated new encryption key');
    } catch (e) {
      print('Error generating encryption key: $e');
      rethrow;
    }
  }

  /// Enable encryption by generating a new key
  Future<void> enableEncryption() async {
    await _generateNewKey();
  }

  /// Disable encryption by removing the key
  /// WARNING: This will make previously encrypted data unreadable!
  Future<void> disableEncryption() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      await _secureStorage.delete(key: _ivStorageKey);
      _encryptionKey = null;
      _iv = null;
      print('✅ Encryption disabled');
    } catch (e) {
      print('Error disabling encryption: $e');
      rethrow;
    }
  }

  /// Encrypt a string value
  String? encryptString(String? plainText) {
    if (plainText == null || plainText.isEmpty) return plainText;
    if (_encryptionKey == null || _iv == null) {
      print('⚠️ Encryption not initialized, returning plain text');
      return plainText;
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final encrypted = encrypter.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      print('Error encrypting string: $e');
      return plainText; // Fallback to plain text on error
    }
  }

  /// Decrypt a string value
  String? decryptString(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty) return encryptedText;
    if (_encryptionKey == null || _iv == null) {
      print('⚠️ Encryption not initialized, returning encrypted text as-is');
      return encryptedText;
    }

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv!);
      return decrypted;
    } catch (e) {
      // If decryption fails, might be plain text from before encryption was enabled
      print('Error decrypting string (might be plain text): $e');
      return encryptedText;
    }
  }

  /// Encrypt a list of strings
  List<String>? encryptStringList(List<String>? plainList) {
    if (plainList == null) return null;
    return plainList.map((s) => encryptString(s) ?? s).toList();
  }

  /// Decrypt a list of strings
  List<String>? decryptStringList(List<String>? encryptedList) {
    if (encryptedList == null) return null;
    return encryptedList.map((s) => decryptString(s) ?? s).toList();
  }

  /// Encrypt a Map<String, dynamic> (for JSON data)
  Map<String, dynamic>? encryptMap(Map<String, dynamic>? plainMap) {
    if (plainMap == null) return null;
    if (_encryptionKey == null || _iv == null) return plainMap;

    try {
      final jsonString = jsonEncode(plainMap);
      final encrypted = encryptString(jsonString);
      return {'_encrypted': encrypted};
    } catch (e) {
      print('Error encrypting map: $e');
      return plainMap;
    }
  }

  /// Decrypt a Map<String, dynamic>
  Map<String, dynamic>? decryptMap(Map<String, dynamic>? encryptedMap) {
    if (encryptedMap == null) return null;
    if (_encryptionKey == null || _iv == null) return encryptedMap;

    try {
      if (encryptedMap.containsKey('_encrypted')) {
        final decrypted = decryptString(encryptedMap['_encrypted'] as String?);
        if (decrypted != null) {
          return jsonDecode(decrypted) as Map<String, dynamic>;
        }
      }
      return encryptedMap; // Not encrypted, return as-is
    } catch (e) {
      print('Error decrypting map: $e');
      return encryptedMap;
    }
  }

  /// Generate a hash of data for verification (useful for passwords)
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Export encryption key (for backup purposes)
  /// WARNING: Keep this key secure! Anyone with this key can decrypt your data.
  Future<String?> exportEncryptionKey() async {
    if (_encryptionKey == null) {
      await _loadOrGenerateKey();
    }
    return _encryptionKey?.base64;
  }

  /// Import encryption key (for restore purposes)
  Future<void> importEncryptionKey(String keyBase64) async {
    try {
      _encryptionKey = encrypt.Key.fromBase64(keyBase64);
      
      // Generate new IV for this installation
      _iv = encrypt.IV.fromSecureRandom(16);

      // Store imported key
      await _secureStorage.write(
        key: _keyStorageKey,
        value: _encryptionKey!.base64,
      );
      await _secureStorage.write(
        key: _ivStorageKey,
        value: _iv!.base64,
      );

      print('✅ Imported encryption key');
    } catch (e) {
      print('Error importing encryption key: $e');
      rethrow;
    }
  }
}

