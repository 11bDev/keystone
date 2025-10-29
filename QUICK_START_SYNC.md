# Quick Start: Google Drive Sync

## ⚡ Fast Setup for Development

### Step 1: Get SHA-1 Fingerprint (Android)
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```
Copy the SHA-1 fingerprint.

### Step 2: Google Cloud Console (5 minutes)
1. Go to: https://console.cloud.google.com/
2. Create new project: "Keystone"
3. Enable "Google Drive API"
4. OAuth consent screen:
   - External
   - App name: "Keystone"
   - Scopes: `../auth/drive.file`
   - Test users: Add your Gmail
5. Create Credentials:
   - OAuth Client ID → Android
   - Package: `com.example.keystone`
   - SHA-1: Paste from Step 1
   - Create

### Step 3: Use in App
1. Open Keystone app
2. Go to Settings
3. Tap "Sign In" under Google Drive Sync
4. Sign in with your Google account
5. Tap "Backup to Google Drive"
6. Done! Your data is now backed up

### Restore Data
On a new device/fresh install:
1. Sign in to Google Drive in app
2. Tap "Restore from Google Drive"
3. Confirm
4. All your data is restored!

---

**That's it!** No more creating test data every time. Just sync and go! 🚀
