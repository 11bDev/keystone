# Keystone v1.1.1 - Bug Fixes & Improvements

## 🐛 Bug Fixes

### Mobile Google Sign-In Persistence
- **Fixed**: Mobile app no longer forces re-login after closing/reopening
- **Improved**: Google Sign-In session now persists between app restarts
- **Enhancement**: Session restoration happens automatically on app startup

### Desktop OAuth Configuration
- **Simplified**: Desktop OAuth credentials now use simple config file
- **Removed**: No more `--dart-define` flags needed for desktop builds
- **Added**: `lib/config/google_credentials.dart` for easy credential management
- **Security**: Credentials file is gitignored automatically

## ✨ New Features

### Sync Improvements
- **Auto-sync on app startup**: App now syncs immediately when launched (if signed in)
- **Auto-sync on changes**: Data syncs automatically whenever tasks/notes/journals are modified
- **Sync log viewer**: New "Sync Log" screen shows last 24 hours of sync activity
  - View all sync attempts (startup, auto, manual)
  - See success/failure status with timestamps
  - Review error messages for failed syncs

### Version Display
- **Dynamic version**: Settings now shows actual app version from pubspec.yaml
- **Format**: Displays as `version+buildNumber` (e.g., 1.1.1+3)

## 📦 Installation

### Android

Download and install the APK:

```bash
# Download
wget https://github.com/11bDev/keystone/releases/download/v1.1.1/keystone_1.1.1.apk

# Install on connected device
adb install keystone_1.1.1.apk
```

**Minimum Requirements:**
- Android 5.0 (API 21) or higher
- ~20MB storage space

### Linux (Debian/Ubuntu)

Download and install the DEB package:

```bash
# Download
wget https://github.com/11bDev/keystone/releases/download/v1.1.1/keystone_1.1.1_amd64.deb

# Install
sudo dpkg -i keystone_1.1.1_amd64.deb
sudo apt-get install -f  # Install dependencies if needed
```

**Minimum Requirements:**
- Ubuntu 22.04+ or equivalent Debian-based distribution
- GTK 3.0+
- ~50MB storage space

## 🔧 Desktop OAuth Setup (New Users)

For desktop (Linux/Windows/macOS), you need to set up Google OAuth credentials:

1. Create `lib/config/google_credentials.dart`:
   ```bash
   cp lib/config/google_credentials.example.dart lib/config/google_credentials.dart
   ```

2. Get credentials from [Google Cloud Console](https://console.cloud.google.com/):
   - Create OAuth 2.0 credentials (Desktop app type)
   - Copy Client ID and Client Secret

3. Edit `lib/config/google_credentials.dart` with your credentials

4. Build and run:
   ```bash
   flutter run -d linux
   ```

See `GOOGLE_SETUP.md` for detailed instructions.

## 🔐 Security Notes

- Desktop credentials file (`lib/config/google_credentials.dart`) is gitignored
- Mobile uses SHA-1 fingerprint authentication (no secrets in code)
- All sync data encrypted in transit via HTTPS
- Local data stored in Hive encrypted boxes

## 📊 Technical Details

### Sync Behavior
- **Startup sync**: Triggers when app launches (if auto-sync enabled and signed in)
- **Change sync**: Triggers silently on any data modification
- **Manual sync**: Available in Settings for on-demand sync
- **Sync log**: Stores last 24 hours of activity, auto-cleans older entries

### Version Info
- **Version**: 1.1.1
- **Build Number**: 3
- **Flutter**: 3.9.2+
- **Dart**: 3.9.2+

## 📝 Changelog

### Added
- Sync log viewer in Settings (last 24 hours)
- Auto-sync on app startup
- Auto-sync on data changes
- Config file for desktop OAuth credentials
- Setup script for easy credential configuration
- Dynamic version display in Settings

### Fixed
- Mobile Google Sign-In session persistence
- Desktop OAuth 400 error with placeholder credentials

### Changed
- Desktop OAuth now uses config file instead of environment variables
- Sync service initializes eagerly to restore sessions
- Version display reads from pubspec.yaml instead of hardcoded value

### Security
- Added `lib/config/google_credentials.dart` to .gitignore
- Created example credentials file for developers

## 🔗 Links

- [Full Documentation](https://github.com/11bDev/keystone)
- [Google OAuth Setup Guide](https://github.com/11bDev/keystone/blob/master/GOOGLE_SETUP.md)
- [Report Issues](https://github.com/11bDev/keystone/issues)

## ✅ Verification

Verify package integrity with SHA256 checksums:

```bash
# Download checksums
wget https://github.com/11bDev/keystone/releases/download/v1.1.1/keystone_1.1.1_checksums.txt

# Verify
sha256sum -c keystone_1.1.1_checksums.txt
```

**Expected checksums:**
```
a06b35f5995405c10b255cbbff940b0ab7c2351ba91e516c8075e7fa5368b70c  keystone_1.1.1.apk
cc3c6be77f51267fa5bf5950bd0819d2ec40af8908df4c37399ef649a2219d38  keystone_1.1.1_amd64.deb
```

---

**Full Changelog**: https://github.com/11bDev/keystone/compare/v1.1.0...v1.1.1
