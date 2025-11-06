# Release Notes - v1.2.1

**Release Date:** November 6, 2025  
**Build Number:** 5

## 🎯 Local-Only Mode for Mobile Users

This release adds a new **Local-Only Mode** option for mobile users, giving them complete control over their data storage and privacy preferences.

---

## ✨ New Features

### Mode Selection Screen (Mobile Only)

- **First Launch Experience:** Beautiful mode selection screen presented to mobile users on first app launch
- **Two Storage Modes:**
  - 📱 **Local Only:** Keep all data on device, no authentication required
  - ☁️ **Cloud Sync:** Sign in to sync data across devices (recommended)
- **Visual Design:** Gradient background with icon-based cards explaining each option
- **Clear Benefits:** Each mode displays its key advantages

### Data Storage Settings (Mobile Only)

- **New Settings Section:** "Data Storage" section in Settings screen
- **Mode Switching:** Users can change between local-only and cloud sync modes anytime
- **Smart Authentication:** Switching to cloud sync automatically prompts for sign-in if needed
- **Status Indicators:** Visual feedback showing current sync status
- **Safety Checks:** Prevents accidental mode changes when already authenticated

### Enhanced Privacy Options

- **No Forced Authentication:** Mobile users can use the app without creating an account
- **Data Ownership:** Local-only mode ensures data never leaves the device
- **Flexible Migration:** Easy transition from local to cloud mode when ready

---

## 🔧 Technical Changes

### Architecture

- Added `appModeProvider` to track user's selected storage mode
- Created `ModeSelectionScreen` with responsive UI
- Updated `AuthWrapper` to handle mode-based routing on mobile
- Added mode selection UI in `SettingsScreen` (mobile only)

### New Files

- `lib/features/auth/mode_selection_screen.dart` - Mode selection UI component

### Modified Files

- `lib/main.dart` - Updated `AuthWrapper` for mode-based routing
- `lib/features/settings/settings_screen.dart` - Added Data Storage section
- `pubspec.yaml` - Version bump to 1.2.1+5

---

## 🎨 User Experience Improvements

### Mode Selection Screen

- **Icon-Based Cards:** Large, clear icons representing each mode
- **Feature Highlights:** Checkmarks listing key benefits
- **Recommended Badge:** Cloud sync marked as recommended option
- **Gradient Background:** Modern aesthetic matching app theme

### Settings Integration

- **Radio Buttons:** Clear selection indicators for current mode
- **Contextual Info:** Helpful messages explaining each mode
- **State Awareness:** Disables options when not applicable
- **Inline Login:** Sign-in dialog appears directly when switching to cloud mode

---

## 📋 Platform Support

| Platform | Mode Selection | Local-Only | Cloud Sync |
|----------|----------------|------------|------------|
| Android  | ✅ Yes         | ✅ Yes     | ✅ Yes     |
| iOS      | ✅ Yes         | ✅ Yes     | ✅ Yes     |
| Web      | ❌ No          | ❌ No      | ✅ Yes     |
| Linux    | ✅ Yes         | ✅ Yes     | ✅ Yes     |

**Note:** Web platform always requires authentication (cloud sync only)

---

## 🔄 Migration Guide

### Upgrading from v1.2.0

1. **Pull Latest Changes:**
   ```bash
   git pull origin master
   git checkout v1.2.1
   ```

2. **Update Dependencies:**
   ```bash
   fvm flutter pub get
   ```

3. **Build for Mobile:**
   ```bash
   # Android
   fvm flutter build apk --release
   
   # iOS
   fvm flutter build ios --release
   ```

4. **Test Mode Selection:**
   - Uninstall previous version (or use fresh install)
   - Launch app on mobile device
   - Verify mode selection screen appears
   - Test both modes

---

## 🎯 Usage Scenarios

### Local-Only Mode Best For:

- ✅ Users who prioritize privacy
- ✅ Single-device usage
- ✅ Offline-only environments
- ✅ No cloud dependency preference
- ✅ Quick start without account creation

### Cloud Sync Mode Best For:

- ✅ Multiple devices (phone, tablet, web)
- ✅ Automatic backups
- ✅ Cross-platform access
- ✅ Collaboration (future feature)
- ✅ Data recovery options

---

## 🐛 Bug Fixes

- Fixed mobile users being forced to authenticate even when not needed
- Improved first-launch user experience on mobile platforms

---

## ⚠️ Breaking Changes

**None.** This is a backward-compatible release.

### For Existing Users:

- Existing authenticated users: Continue using cloud sync mode automatically
- Existing local installations: Will see mode selection on next launch (can choose local-only to maintain current behavior)

---

## 📦 Release Assets

### APK Information

- **File:** `app-release.apk`
- **Size:** 56.8 MB
- **SHA256:** `854234120a63077c8c839e9883508b65f66d36641473589bae4b53c93ae9e4ba`

### Web Deployment

- **URL:** https://keystone-1424f.web.app
- **Status:** Updated with latest changes
- **Mode:** Cloud sync only (authentication required)

---

## 🔜 Future Enhancements

Based on this release, we're planning:

1. **Data Export/Import:** Allow users to export local data and import to cloud
2. **Selective Sync:** Choose which data categories to sync
3. **Conflict Resolution:** Better handling of sync conflicts
4. **Offline Indicator:** Visual indicator of sync status
5. **Data Migration Tool:** One-click migration from local to cloud

---

## 🙏 Acknowledgments

This release focuses on user choice and privacy, allowing users to control how and where their data is stored. Thank you to all users who requested this feature!

---

## 🔗 Resources

- **GitHub Repository:** https://github.com/11bDev/keystone
- **Firebase Console:** https://console.firebase.google.com/project/keystone-1424f
- **Web App:** https://keystone-1424f.web.app
- **Release Notes:** See all releases at https://github.com/11bDev/keystone/releases

---

## 📝 Changelog

### Added
- Mode selection screen for mobile users on first launch
- Local-only storage mode option
- Data Storage section in Settings (mobile only)
- Mode switching capability with authentication prompts
- Visual indicators for current storage mode

### Changed
- Mobile users no longer forced to authenticate on first launch
- AuthWrapper now handles mode-based routing

### Fixed
- Mobile authentication flow respects user preferences
- Improved privacy options for single-device users

---

**Full Changelog:** v1.2.0...v1.2.1
