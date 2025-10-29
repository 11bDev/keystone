# Google Drive Sync Setup Guide

Your Keystone app now has Google Drive sync functionality! This guide will walk you through setting it up.

## ✨ Features

- **Automatic Backup**: Save all your tasks, notes, and journal entries to Google Drive
- **Easy Restore**: Restore your data from any device with your Google account
- **Secure Storage**: Data is stored in JSON format in your personal Google Drive
- **No More Test Data**: Create data once, sync it everywhere!

## 📱 How to Use (Already Working!)

1. **Open Settings**: Tap the settings icon in the app
2. **Sign In**: Tap "Sign In" under Google Drive Sync
3. **Authenticate**: Sign in with your Google account
4. **Backup**: Tap "Backup to Google Drive" to save your data
5. **Restore**: On another device or after reinstalling, tap "Restore from Google Drive"

## 🔧 Platform Setup Required

### For Android

To use Google Sign-In on Android, you need to configure OAuth credentials:

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/

2. **Create a Project** (if you don't have one)
   - Click "Select a project" → "New Project"
   - Name it "Keystone" or similar
   - Click "Create"

3. **Enable Google Drive API**
   - In the search bar, type "Google Drive API"
   - Click on it and press "Enable"

4. **Configure OAuth Consent Screen**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Choose "External" (for personal use)
   - Fill in the app name: "Keystone"
   - Add your email as support email
   - Skip optional fields
   - Add scopes: `../auth/drive.file`
   - Add yourself as a test user
   - Click "Save and Continue"

5. **Create OAuth 2.0 Client ID for Android**
   - Go to "Credentials" → "Create Credentials" → "OAuth client ID"
   - Application type: "Android"
   - Name: "Keystone Android"
   - Package name: `com.example.keystone`
   - Get your SHA-1 certificate fingerprint:
     ```bash
     # For debug builds (development):
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # Copy the SHA-1 fingerprint and paste it in the Google Cloud Console
     ```
   - Click "Create"

6. **Download and Add google-services.json** (Optional but recommended)
   - You can download the configuration file
   - Place it in `android/app/google-services.json`

### For Linux

Linux support for Google Sign-In works through web authentication. No additional setup needed - it will open a browser for sign-in!

### For iOS (Future)

If you build for iOS:

1. Create an OAuth Client ID for iOS in Google Cloud Console
2. Add the URL scheme to `ios/Runner/Info.plist`
3. Add your iOS bundle identifier

## 🗂️ What Gets Backed Up?

All your data is exported to a single JSON file (`keystone_backup.json`) in a folder called "Keystone" in your Google Drive:

- ✅ All Tasks (with due dates, tags, categories, status)
- ✅ All Notes (with content, titles, tags, creation dates)
- ✅ All Journal Entries (with body, tags, dates, image paths)

**Note**: Images themselves are NOT uploaded to Google Drive, only their local paths. If you want to preserve images, you'll need to manually back them up or we can extend the sync to include image uploads.

## 🔐 Security & Privacy

- Your data is stored in **your personal Google Drive**
- Only you have access to the backup file
- The app only requests permission to access files it creates (`drive.file` scope)
- It cannot access other files in your Google Drive

## 🐛 Troubleshooting

### "Failed to sign in"
- Make sure you've set up the OAuth credentials correctly
- Check that you added yourself as a test user in OAuth consent screen
- Verify the package name matches: `com.example.keystone`

### "No backup found"
- You need to create a backup first before you can restore
- Make sure you're signed in with the same Google account

### "Backup failed"
- Check your internet connection
- Ensure Google Drive API is enabled
- Verify OAuth consent screen is configured

### Linux Sign-In Issues
- Make sure you have a default web browser configured
- The app will open a browser for authentication
- After signing in, return to the app

## 📝 Technical Details

- **Backup Format**: JSON
- **Storage Location**: Google Drive → Keystone folder
- **File Name**: `keystone_backup.json`
- **Data Structure**:
  ```json
  {
    "version": "1.0",
    "timestamp": "2025-10-29T...",
    "tasks": [...],
    "notes": [...],
    "journalEntries": [...]
  }
  ```

## 🚀 Future Enhancements

Potential features to add:
- Automatic sync on app launch/close
- Sync images to Google Drive
- Multiple backup versions (history)
- Encrypted backups for extra security
- Conflict resolution for edits on multiple devices
- Selective restore (choose what to restore)

## ⚠️ Important Notes

1. **Restore replaces all data**: When you restore from backup, it will replace ALL current data
2. **Test first**: Try backup/restore with test data before using with real data
3. **Internet required**: Both backup and restore require an internet connection
4. **First backup**: The first backup will create the Keystone folder in your Drive

---

Enjoy never having to create test data again! 🎉
