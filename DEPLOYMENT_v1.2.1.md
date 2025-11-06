# Keystone v1.2.1 Deployment Summary

**Release Date:** November 6, 2025  
**Version:** 1.2.1+5

## 🚀 Deployment Status

### ✅ Android APK
- **Location:** `build/app/outputs/flutter-apk/app-release.apk`
- **Size:** 56.8 MB (54.21 MiB)
- **Build Time:** 111.6s
- **Status:** Successfully Built & Released

### ✅ Web Application
- **Hosting:** Firebase Hosting
- **URL:** https://keystone-1424f.web.app
- **Status:** Successfully Deployed
- **Files:** 34 files uploaded from build/web
- **Build Time:** 36.3s

### ✅ GitHub Release
- **Tag:** v1.2.1
- **URL:** https://github.com/11bDev/keystone/releases/tag/v1.2.1
- **APK Attached:** ✅ Yes
- **Release Notes:** ✅ RELEASE_v1.2.1.md

## 🔐 Checksums

### app-release.apk (v1.2.1)
```
SHA256: 854234120a63077c8c839e9883508b65f66d36641473589bae4b53c93ae9e4ba
```

Full checksums available in: `keystone_1.2.1_checksums.txt`

## 📋 Build Details

### Web Build
- **Build Command:** `fvm flutter build web --release`
- **Output Directory:** `build/web`
- **Icon Tree-Shaking:**
  - CupertinoIcons: 257,628 → 1,472 bytes (99.4% reduction)
  - MaterialIcons: 1,645,184 → 11,856 bytes (99.3% reduction)
- **Compile Time:** 36.3s

### Android Build
- **Build Command:** `fvm flutter build apk --release`
- **Output:** `build/app/outputs/flutter-apk/app-release.apk`
- **Icon Tree-Shaking:**
  - MaterialIcons: 1,645,184 → 6,172 bytes (99.6% reduction)
- **Gradle Time:** 111.6s

## 🎯 Release Highlights

### New Features
- **Mode Selection Screen:** Beautiful UI for mobile users to choose storage mode
- **Local-Only Mode:** Use app without authentication, data stays on device
- **Cloud Sync Mode:** Sign in to sync across devices
- **Data Storage Settings:** New settings section to switch modes
- **Smart Authentication:** Auto-prompt for sign-in when switching to cloud mode

### Technical Changes
- Added `appModeProvider` for mode state management
- Created `ModeSelectionScreen` component
- Updated `AuthWrapper` with mode-based routing
- Enhanced Settings screen with Data Storage section

## 🌐 Deployment Configuration

### Firebase Hosting
**firebase.json:**
```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**.firebaserc:**
```json
{
  "projects": {
    "default": "keystone-1424f"
  }
}
```

## 📱 Distribution

### Web Application
Users can access the application at:
```
https://keystone-1424f.web.app
```

Features:
- Authentication required (cloud sync only)
- Google Sign-In support
- Email/password authentication
- Responsive design
- Progressive Web App

### Android APK Installation

**Download:**
- GitHub Release: https://github.com/11bDev/keystone/releases/tag/v1.2.1
- Direct Asset: `app-release.apk`

**Verify Checksum:**
```bash
sha256sum app-release.apk
# Should match: 854234120a63077c8c839e9883508b65f66d36641473589bae4b53c93ae9e4ba
```

**Install:**
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer to device and tap to install
```

## 🔄 Version History

| Version | Release Date | Key Feature | APK Size |
|---------|--------------|-------------|----------|
| v1.2.1  | Nov 6, 2025  | Local-Only Mode | 56.8 MB |
| v1.2.0  | Nov 6, 2025  | Multi-Tenant Auth | 56.6 MB |
| v1.1.1  | -            | Previous Release | - |

## 🎨 Platform-Specific Features

### Mobile (Android/iOS)
- ✅ Mode selection screen on first launch
- ✅ Local-only mode option
- ✅ Cloud sync mode option
- ✅ Data Storage settings section
- ✅ Mode switching capability

### Web
- ✅ Landing page for unauthenticated users
- ✅ Google Sign-In
- ✅ Email/password authentication
- ✅ Cloud sync (required)
- ❌ Local-only mode (N/A for web)

### Desktop (Linux)
- ✅ Mode selection screen
- ✅ Local-only mode option
- ✅ Cloud sync mode option
- ✅ Full feature parity with mobile

## 🔧 Deployment Commands

### Redeploy Web
```bash
fvm flutter build web --release
firebase deploy --only hosting
```

### Rebuild APK
```bash
fvm flutter build apk --release
```

### Create New Release
```bash
# Bump version in pubspec.yaml
# Build APK and web
# Generate checksums
sha256sum build/app/outputs/flutter-apk/app-release.apk > keystone_VERSION_checksums.txt

# Commit and tag
git add -A
git commit -m "chore: Release vX.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z - Description"
git push origin master
git push origin vX.Y.Z

# Create GitHub release
gh release create vX.Y.Z \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "vX.Y.Z - Title" \
  --notes-file RELEASE_vX.Y.Z.md
```

## ✅ Verification Checklist

- [x] Version bumped in pubspec.yaml (1.2.1+5)
- [x] APK built successfully (56.8 MB)
- [x] Web built successfully (34 files)
- [x] Checksums generated
- [x] Release notes created (RELEASE_v1.2.1.md)
- [x] Changes committed to git
- [x] Git tag created (v1.2.1)
- [x] Pushed to GitHub (master + tag)
- [x] GitHub release created
- [x] APK attached to release
- [x] Web deployed to Firebase Hosting
- [x] Firebase deployment successful
- [x] Web app accessible at https://keystone-1424f.web.app

## 📊 Build Statistics

### Package Dependencies
- 27 packages with newer versions available (constraint limited)
- All required dependencies resolved successfully
- No breaking changes in build process

### Build Performance
- **Web Compile:** 36.3s (↓ 0.3s from v1.2.0)
- **Android Gradle:** 111.6s (↓ 66.3s from v1.2.0)
- **Total Build Time:** ~148s

### Optimization Results
- **Icon Tree-Shaking:** 99.3-99.6% reduction
- **APK Size Change:** +0.2 MB (minimal increase)
- **Web Bundle:** Optimized and minified

## 🔗 Resources

- **GitHub Repository:** https://github.com/11bDev/keystone
- **Release Page:** https://github.com/11bDev/keystone/releases/tag/v1.2.1
- **Web App:** https://keystone-1424f.web.app
- **Firebase Console:** https://console.firebase.google.com/project/keystone-1424f
- **Changelog:** v1.2.0...v1.2.1

---

**Deployment Completed:** November 6, 2025  
**Deployed By:** Automated build system  
**Status:** ✅ Production Ready
