# 🔒 End-to-End Encryption in Keystone

## Overview

Keystone now supports **end-to-end encryption (E2E)** for all user data synced to Firestore. This ensures that even Google/Firebase administrators cannot read your data - only you can decrypt it with your encryption key stored locally on your device.

## How It Works

### Zero-Knowledge Architecture

1. **Client-Side Encryption**: All data is encrypted on YOUR device before being sent to Firestore
2. **AES-256 Encryption**: Military-grade encryption algorithm
3. **Secure Key Storage**: Encryption key stored in device's secure storage (Keychain on iOS, KeyStore on Android)
4. **Server Blindness**: Firestore only stores encrypted gibberish - unreadable without your key

### Encryption Flow

```
User Data → Encrypt (AES-256) → Firestore (encrypted)
                ↓
         Encryption Key
         (Stays on Device)

Firestore (encrypted) → Decrypt (AES-256) → User Data
                         ↓
                  Encryption Key
                  (From Device)
```

## What Gets Encrypted

### ✅ Encrypted Fields

- **Tasks**:
  - Task title/text
  - Notes attached to tasks
  - Tags

- **Notes**:
  - Note titles
  - Note content
  - Tags

- **Journal Entries**:
  - Entry content
  - Tags

### ❌ NOT Encrypted (Required for Functionality)

- Timestamps (needed for sync conflict resolution)
- Task status (pending/done/cancelled/migrated)
- Data type markers
- Firestore document IDs
- Category indicators (task/event)

## Security Features

### Encryption Specifications

- **Algorithm**: AES-256-CBC
- **Key Size**: 256 bits (32 bytes)
- **IV Size**: 128 bits (16 bytes)
- **Key Generation**: Cryptographically secure random
- **Key Storage**: Platform secure storage (flutter_secure_storage)

### Security Best Practices

✅ **What Keystone Does**:
- Generates cryptographically secure random keys
- Stores keys in platform secure storage
- Encrypts data before network transmission
- Never sends encryption key to server
- Uses authenticated encryption (prevents tampering)

⚠️ **User Responsibilities**:
- Export and backup your encryption key
- Store backup key in a password manager
- Don't share your encryption key
- Understand that lost keys = lost data

## Usage

### Enabling Encryption

1. Open **Settings** screen
2. Navigate to **Privacy & Encryption** section
3. Toggle **End-to-End Encryption** ON
4. Confirm the dialog
5. **IMPORTANT**: Export and backup your encryption key!

### Exporting Encryption Key

1. Go to **Settings** → **Privacy & Encryption**
2. Tap **Export Encryption Key**
3. Copy the key and save it securely (password manager recommended)
4. This key is needed to decrypt your data on other devices

### Disabling Encryption

⚠️ **Warning**: Disabling encryption will make previously encrypted cloud data unreadable!

1. Go to **Settings** → **Privacy & Encryption**
2. Toggle **End-to-End Encryption** OFF
3. Confirm the warning dialog

## Technical Implementation

### Files Added

- `lib/services/encryption_service.dart` - Core encryption logic
- `lib/services/encrypted_model_helper.dart` - Model encryption/decryption
- `lib/providers/encryption_provider.dart` - Riverpod state management

### Dependencies

```yaml
dependencies:
  encrypt: ^5.0.3  # AES encryption
  flutter_secure_storage: ^9.2.2  # Secure key storage
  crypto: ^3.0.6  # Hashing utilities
```

### Code Example

```dart
// Initialize encryption service
final encryptionService = EncryptionService();
await encryptionService.initialize();

// Encrypt a string
final encrypted = encryptionService.encryptString("My secret task");
// Result: "aGVsbG8gd29ybGQ=" (base64 encrypted)

// Decrypt a string
final decrypted = encryptionService.decryptString(encrypted);
// Result: "My secret task"
```

## Data Migration

### Upgrading from Unencrypted to Encrypted

When you enable encryption:

1. **New data** will be encrypted automatically
2. **Existing cloud data** remains unencrypted (readable)
3. **Gradual migration**: Data gets encrypted as you edit it
4. **Local data** is always readable (encryption only affects cloud sync)

### Backward Compatibility

The system handles both encrypted and unencrypted data:

```dart
// Data structure includes encryption marker
{
  "_encrypted": true,  // Indicates encrypted data
  "text": "aGVsbG8=",  // Encrypted value
  "dueDate": "2025-11-07",  // Plain timestamp
  "status": "pending"  // Plain status
}
```

## Privacy Guarantees

### What Google/Firebase CANNOT See

- ❌ Task titles and descriptions
- ❌ Note content
- ❌ Journal entries
- ❌ Tag names
- ❌ Any encrypted field content

### What Google/Firebase CAN See

- ✅ When you created/modified data (timestamps)
- ✅ How many tasks/notes you have (counts)
- ✅ Task statuses (done/pending)
- ✅ Your email address (Firebase Auth)
- ✅ Encrypted blobs (unreadable gibberish)

## Limitations

### Current Limitations

1. **Search**: Encrypted data cannot be searched server-side
   - Solution: Search works locally after decryption
   
2. **Shared Access**: Cannot share encrypted data with others
   - Future: Implement asymmetric encryption for sharing
   
3. **Key Recovery**: Lost key = lost data
   - Mitigation: Clear warnings + easy key export

### Future Enhancements

Planned improvements:

1. **Password-Based Encryption**: Derive key from user password
2. **Key Derivation Function**: Use PBKDF2 or Argon2
3. **Recovery Key**: Generate backup recovery key
4. **Multi-Device Sync**: Secure key distribution across devices
5. **Field-Level Encryption**: Encrypt specific fields selectively
6. **Asymmetric Encryption**: RSA for data sharing

## FAQ

### Q: Is this really secure?

**A**: Yes! We use AES-256 (same encryption used by banks and militaries). Your key never leaves your device. Even if someone hacks Firestore, they only get encrypted gibberish.

### Q: What happens if I lose my phone?

**A**: If you exported your encryption key, you can restore it on a new device. If not, your cloud data is permanently unreadable. Local data is lost with the phone.

### Q: Can I use this offline?

**A**: Yes! Encryption/decryption happens locally. Works perfectly offline.

### Q: Does encryption slow down the app?

**A**: Minimal impact. AES is extremely fast on modern devices. You won't notice any difference.

### Q: Can Google recover my data if I lose my key?

**A**: No. That's the point of end-to-end encryption! Not even Google can decrypt your data.

### Q: Should I enable encryption?

**A**: 
- ✅ **Yes, if**: You want maximum privacy and handle sensitive data
- ❌ **No, if**: You don't want the responsibility of managing encryption keys

## Support

If you have questions or issues with encryption:

1. Check this documentation
2. Review the **Encryption Info** dialog in Settings
3. Open an issue on GitHub
4. Contact support with your question

---

**Remember**: With great privacy comes great responsibility. Export and secure your encryption key! 🔑
