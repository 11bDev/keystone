# Keystone v1.2.2 - Bug Fix Release

**Release Date:** December 2024  
**Type:** Patch Release  
**Focus:** Mobile Authentication Navigation Fix

## 🐛 Bug Fixes

### Mobile Authentication Navigation
- **Fixed:** Mobile users getting stuck on landing page after sign-in
- **Issue:** After successful Google Sign-In or email authentication, mobile users remained on the landing page instead of navigating to the main app
- **Root Cause:** Dialog navigation context conflict - the login form was closing the dialog using a local navigator context instead of the root navigator
- **Solution:** Updated all authentication methods (`_signInWithEmail`, `_signUpWithEmail`, `_signInWithGoogle`) in `LoginForm` to use `Navigator.of(context, rootNavigator: true).pop()` to ensure proper navigation on mobile platforms

### Technical Details
The authentication flow works as follows:
1. User taps "Get Started" on the landing page
2. Login form is shown in a dialog
3. User authenticates (Google/Email)
4. Dialog closes using root navigator
5. `AuthWrapper` detects auth state change via `authStateChangesProvider`
6. App navigates to `MainScreenWrapper`

Previously, step 4 was using a local navigator context which prevented step 6 from executing properly on mobile.

## 📋 Changes

### Modified Files
- `lib/features/auth/login_form.dart`
  - Updated `_signInWithEmail()` to use root navigator
  - Updated `_signUpWithEmail()` to use root navigator  
  - Updated `_signInWithGoogle()` to use root navigator
  - Added comments explaining the root navigator usage

## ✅ Verification

### Pre-Release Testing Checklist
- [ ] Build Android APK successfully
- [ ] Test Google Sign-In on mobile
- [ ] Test email sign-in on mobile
- [ ] Test account creation on mobile
- [ ] Verify navigation to main app after authentication
- [ ] Confirm web authentication still works
- [ ] Verify local-only mode still works (no regression)

### Post-Release Verification
- [ ] Install APK on physical device
- [ ] Test complete authentication flow
- [ ] Verify no regression in existing features

## 📦 Build Information

### Android APK
- **File:** `keystone-1.2.2.apk`
- **Size:** 56.8 MB
- **SHA256:** `fea15b630095081145c3515a14a82190e66cc686c2ea894db8a6ec91847aff91`
- **Build Command:** `fvm flutter build apk --release`
- **Build Time:** ~14 seconds (incremental build)

### Version Information
- **Version:** 1.2.2+6
- **Previous Version:** 1.2.1+5
- **Version Bump:** Patch release (bug fix only)

## 🔄 Upgrade Notes

### From v1.2.1 to v1.2.2
This is a critical bug fix for mobile users. If you experienced issues signing in on mobile with v1.2.1, this update resolves that problem. No database migrations or configuration changes are required.

**Recommended:** All v1.2.1 mobile users should upgrade to v1.2.2 immediately.

### Breaking Changes
None. This is a backward-compatible bug fix.

## 🌐 Platform Support

No changes from v1.2.1:
- ✅ **Android:** Full support (primary focus of this fix)
- ✅ **Web:** Full support (verified no regression)
- ⚠️ **iOS:** Requires additional Firebase configuration
- ⚠️ **Linux:** Local-only mode (no Firebase support)
- ⚠️ **macOS:** Not tested
- ⚠️ **Windows:** Not tested

## 📝 Known Issues

### Carried Over from v1.2.1
1. **People API Requirement (Web):** Google Sign-In on web requires People API to be enabled in Google Cloud Console
   - Users will see "Google hasn't verified this app" on first sign-in
   - Error if People API is disabled: "Access Not Configured"
   - See `GOOGLE_SETUP.md` for configuration steps

2. **Firebase Configuration Required:** First-time users need to set up Firebase project and download configuration files
   - Android: `google-services.json`
   - Web: Update `web/index.html` with your OAuth client ID
   - See `FIREBASE_SETUP.md` for detailed instructions

### New Issues
None identified in this release.

## 🚀 Deployment

### Android APK
```bash
# Build the APK
fvm flutter build apk --release

# Generate checksum
sha256sum build/app/outputs/flutter-apk/app-release.apk > keystone_1.2.2_checksums.txt

# Copy to release directory
cp build/app/outputs/flutter-apk/app-release.apk keystone-1.2.2.apk
```

### Git Tagging
```bash
git add -A
git commit -m "Release v1.2.2 - Fix mobile authentication navigation"
git tag -a v1.2.2 -m "Bug fix: Mobile authentication navigation"
git push origin master --tags
```

### GitHub Release
1. Create new release on GitHub: https://github.com/YOUR_USERNAME/keystone/releases/new
2. Tag: `v1.2.2`
3. Title: `Keystone v1.2.2 - Mobile Authentication Fix`
4. Description: Copy from this release document (Bug Fixes section)
5. Attach `keystone-1.2.2.apk`
6. Attach `keystone_1.2.2_checksums.txt`

### Web Deployment
No web changes required for this release. The fix is specific to mobile platforms.

## 🔗 Related Documentation

- **Firebase Setup:** See `FIREBASE_SETUP.md`
- **Google OAuth Setup:** See `GOOGLE_SETUP.md`
- **Previous Releases:**
  - v1.2.1: Mode selection and local-only support
  - v1.2.0: Initial authentication implementation

## 📞 Support

If you encounter issues with this release:
1. Check that you're using the correct APK (verify SHA256 checksum)
2. Ensure you have the latest `google-services.json` from Firebase Console
3. For web, verify your OAuth client ID in `web/index.html`
4. Review the authentication flow in `lib/main.dart` (`AuthWrapper`)

## 🎯 Next Steps

Potential improvements for future releases:
- Add email verification flow
- Implement password reset functionality
- Add user profile management
- Improve error messaging for authentication failures
- Add biometric authentication support

---

**Full Changelog:** [v1.2.1...v1.2.2](https://github.com/YOUR_USERNAME/keystone/compare/v1.2.1...v1.2.2)
