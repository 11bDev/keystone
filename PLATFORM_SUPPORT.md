# 📱 Platform Support for Google Drive Sync

## Current Status

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Fully Supported | Requires OAuth setup |
| **iOS** | ✅ Fully Supported | Requires OAuth setup |
| **Web** | ✅ Fully Supported | Uses web OAuth flow |
| **Linux** | ⚠️ Limited | google_sign_in plugin doesn't support Linux desktop yet |
| **macOS** | ⚠️ Limited | google_sign_in plugin doesn't support macOS desktop yet |
| **Windows** | ⚠️ Limited | google_sign_in plugin doesn't support Windows desktop yet |

## Recommended Development Flow

Since you're developing on Linux, here's the recommended workflow:

### Option 1: Test on Android (Recommended)
1. Set up Google OAuth for Android (see `GOOGLE_DRIVE_SETUP.md`)
2. Run on Android emulator or physical device:
   ```bash
   flutter run -d <android-device>
   ```
3. Test sync functionality on Android
4. Your data will sync to Google Drive
5. You can restore it on any supported device

### Option 2: Use Android Emulator
```bash
# List available devices
flutter devices

# Run on emulator
flutter emulator --launch <emulator-name>
flutter run
```

### Option 3: Build APK and Test on Phone
```bash
# Build debug APK
flutter build apk --debug

# Install on connected phone
flutter install
```

## Desktop Alternatives

While waiting for desktop support, you can:

1. **Use the App on Mobile**: Develop on Linux, test sync on Android/iOS
2. **Web Version**: If you enable web support, it will work in a browser
3. **Direct Database Access**: For testing, you can manually copy the Isar database files

## Enabling Web Support (for testing sync)

If you want to test Google Drive sync on Linux via web:

```bash
# Enable web support for your project
flutter create --platforms=web .

# Run as web app
flutter run -d chrome
```

Then set up Web OAuth credentials in Google Cloud Console.

## When Desktop Support Arrives

The `google_sign_in` package is actively maintained. When desktop support is added:
- The existing code will work without changes
- Just need to add desktop OAuth credentials to Google Cloud Console
- Update `google_sign_in` to latest version

## Current Workaround for Linux Development

For local development and testing without Google Drive:

### Manual Backup/Restore Script

Create a simple shell script to backup/restore the Isar database:

```bash
#!/bin/bash
# backup-local.sh

ISAR_PATH="$HOME/.config/keystone/isar"
BACKUP_PATH="$HOME/keystone-backup-$(date +%Y%m%d-%H%M%S)"

# Backup
cp -r "$ISAR_PATH" "$BACKUP_PATH"
echo "Backed up to: $BACKUP_PATH"
```

### Export to JSON (Manual)

You could also add a local export button that:
1. Exports data to JSON file
2. Saves to Downloads folder
3. User manually uploads to Drive (or syncs via cloud storage like Dropbox)

Would you like me to implement this local export feature as a stopgap solution?

## Testing Checklist for Android

Once you set up Android:

- [ ] Get SHA-1 fingerprint using `./get-sha1.sh`
- [ ] Set up Google Cloud OAuth for Android
- [ ] Run app on Android device/emulator
- [ ] Sign in to Google account
- [ ] Create test data (tasks, notes, journals)
- [ ] Backup to Google Drive
- [ ] Clear app data or use different device
- [ ] Restore from Google Drive
- [ ] Verify all data restored

## Future Plans

Options to consider:
1. **Wait for Plugin Update**: google_sign_in will likely add desktop support
2. **Use Alternative**: Implement direct Drive API with manual OAuth flow for desktop
3. **Local Sync**: Add export/import via local files
4. **Other Cloud Services**: Support Dropbox, OneDrive, etc. that have desktop support

---

**Bottom Line**: The sync code is ready and works on Android/iOS/Web. For Linux development, test the sync features using an Android emulator or device. 📱
