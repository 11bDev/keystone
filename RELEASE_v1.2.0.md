# Release Notes - v1.2.0

**Release Date:** November 6, 2025  
**Build Number:** 4

## 🎉 Web Multi-Tenant Authentication

This major release introduces comprehensive web authentication support, enabling multi-tenant access to the Keystone productivity platform through Firebase Authentication and Google Sign-In.

---

## ✨ New Features

### Authentication System
- **Firebase Authentication Integration**: Full Firebase Auth implementation with email/password and Google provider support
- **Google Sign-In**: Seamless Google account authentication for web users
- **Multi-Tenant Support**: User-scoped data isolation and authentication state management
- **Auth State Management**: Automatic route handling based on authentication status using Riverpod

### User Interface
- **Landing Page**: Beautiful gradient-based landing page showcasing app features
  - Feature cards for Tasks, Notes, Journal, Calendar, and Projects
  - Responsive design optimized for web
  - Clean, modern aesthetic matching the app theme
  
- **Login/Signup Form**: Comprehensive authentication UI
  - Email and password authentication
  - Google Sign-In button with branding
  - Form validation and error handling
  - Loading states and user feedback
  - Modal popup presentation

- **Auth Wrapper**: Smart navigation component
  - Shows landing page for unauthenticated users on web
  - Automatically navigates to main app after successful sign-in
  - Handles loading and error states gracefully

### Settings Integration
- Auth status display in settings screen (web only)
- Sign-in/Sign-out functionality
- User email display when authenticated

---

## 🔧 Technical Changes

### Configuration
- Added `web/index.html` with Google Sign-In meta tags
- Configured correct web OAuth client ID (client_type 3)
- Fixed OAuth client type mismatch (previously using iOS client ID)
- Added auth state stream providers in Riverpod

### Dependencies
- **Downgraded** `google_sign_in` to `6.3.0` for API compatibility
- **Added** `firebase_auth: ^5.3.3`
- **Added** authentication-related packages

### Architecture
- Created `AuthService` class for authentication logic
- Implemented `AuthWrapper` for route protection
- Added `authStateChangesProvider` stream for real-time auth updates
- Integrated Firebase Auth with existing Firestore setup

---

## 🐛 Bug Fixes

- Fixed OAuth client type mismatch (was using iOS client ID for web)
- Corrected Google Sign-In client ID configuration in `web/index.html`
- Fixed navigation flow after successful authentication
- Resolved dialog closing behavior in login form
- Added proper People API support for user profile information

---

## 📋 Setup Requirements

### For Users
1. **Enable People API**: Visit [Google Cloud Console](https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=4572425885) and enable the People API
2. **Configure Firebase Authentication**: Enable Google sign-in provider in Firebase Console
3. **Wait for Propagation**: After enabling APIs, wait a few minutes for changes to propagate

### For Developers
- Ensure Firebase project is properly configured
- Verify `web/index.html` contains correct OAuth client ID
- Check that Firebase Authentication has Google provider enabled

---

## ⚠️ Breaking Changes

### Web Platform
- **Authentication Required**: Web users must now sign in before accessing the app
- **New Landing Page**: Unauthenticated users see landing page instead of direct app access
- **Google Sign-In API**: Downgraded to version 6.3.0 (some deprecated methods)

### Mobile Platform
- No breaking changes for mobile users
- Existing functionality remains unchanged

---

## 📦 Files Changed

### New Files
- `lib/features/auth/login_form.dart` - Login/signup form component
- `lib/features/landing/landing_page.dart` - Web landing page
- `lib/providers/auth_provider.dart` - Authentication providers
- `lib/services/auth_service.dart` - Authentication service
- `web/index.html` - Web entry point with OAuth config
- `web/manifest.json` - Web app manifest
- `web/icons/*` - Web app icons

### Modified Files
- `lib/main.dart` - Added AuthWrapper and routing logic
- `lib/features/settings/settings_screen.dart` - Added auth UI (web only)
- `pubspec.yaml` - Updated dependencies

### Removed Files
- Cleaned up deprecated Hive-based sync services
- Removed old generated files

---

## 🔜 Known Issues

1. **People API Requirement**: Must be manually enabled in Google Cloud Console
2. **Propagation Delay**: API enablement may take a few minutes to activate
3. **Google Sign-In Deprecation**: Current implementation uses deprecated web API (will be updated in future release)

---

## 🙏 Acknowledgments

This release enables the foundation for multi-tenant web access, paving the way for collaborative features and cloud-based productivity workflows.

---

## 📝 Migration Guide

### Upgrading from v1.1.1

1. **Pull Latest Changes**:
   ```bash
   git pull origin master
   git checkout v1.2.0
   ```

2. **Update Dependencies**:
   ```bash
   fvm flutter pub get
   ```

3. **Enable People API**:
   - Visit the Google Cloud Console link provided
   - Click "Enable" for People API
   - Wait 2-3 minutes

4. **Test Authentication**:
   - Run on web: `fvm flutter run -d chrome`
   - Click "Get Started" on landing page
   - Try signing in with Google

5. **Verify Firebase**:
   - Check Firebase Console for Authentication provider
   - Ensure Google sign-in is enabled

---

## 🔗 Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Google Sign-In for Web](https://developers.google.com/identity/sign-in/web)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

**Full Changelog**: v1.1.1...v1.2.0
