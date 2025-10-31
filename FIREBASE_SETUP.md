# Firebase Setup Guide for Keystone

This guide will help you set up Firebase and Cloud Firestore for the Keystone app.

## Prerequisites

- A Google account
- Access to [Firebase Console](https://console.firebase.google.com/)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: **keystone-app** (or your preferred name)
4. (Optional) Enable Google Analytics
5. Click "Create project"
6. Wait for the project to be created

## Step 2: Add Android App to Firebase

1. In your Firebase project, click the **Android** icon
2. Fill in the details:
   - **Android package name**: `com.example.keystone` (must match your app)
   - **App nickname** (optional): Keystone Android
   - **Debug signing certificate SHA-1**: Get from terminal:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android | grep SHA1
     ```
3. Click "Register app"
4. **Download** `google-services.json`
5. Place it in: `android/app/google-services.json`
6. Click "Next" through the SDK setup (dependencies already added)
7. Click "Continue to console"

## Step 3: Add Linux/Desktop App to Firebase

1. In Firebase Console, click "Add app" → Select **Web** (for desktop)
2. Fill in details:
   - **App nickname**: Keystone Desktop
   - ✅ Check "Also set up Firebase Hosting" (optional)
3. Click "Register app"
4. Copy the Firebase configuration object
5. Save it for Step 6 below

## Step 4: Enable Firestore Database

1. In Firebase Console sidebar, click **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (for development)
   - ⚠️ **Production**: Change rules later for security
4. Choose a location (e.g., `us-central1`)
5. Click **Enable**

### Production Security Rules (Apply Later)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 5: Enable Authentication

1. In Firebase Console sidebar, click **Authentication**
2. Click **Get started**
3. Click on **Google** sign-in provider
4. Toggle **Enable**
5. Select a support email
6. Click **Save**

## Step 6: Configure Flutter App

### For Android:

1. Add classpath to `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.2")
   }
   ```

2. Apply plugin in `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // Add this
   }
   ```

3. Ensure `google-services.json` is in `android/app/`

### For Linux/Desktop:

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Paste your Web config from Firebase Console here
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // Android options (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // Linux (use web config)
  static FirebaseOptions get linux => web;
  
  // Windows (use web config)
  static FirebaseOptions get windows => web;
  
  // macOS (use web config)
  static FirebaseOptions get macos => web;
  
  // iOS (similar to Android, from GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.keystone',
  );
}
```

## Step 7: Initialize Firebase in App

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // ... rest of initialization
  runApp(const MyApp());
}
```

## Step 8: Test the Setup

Run the app:

```bash
flutter run -d linux
```

Check for:
- ✅ No Firebase initialization errors
- ✅ Authentication works with Google Sign-In
- ✅ Firestore connection established

## Troubleshooting

### Android: "google-services.json not found"
- Ensure file is in `android/app/google-services.json`
- Run `flutter clean && flutter build apk`

### Desktop: "Firebase not initialized"
- Check `firebase_options.dart` has correct values
- Verify API keys match Firebase Console

### Firestore: "Permission denied"
- Check Firestore rules allow access
- Ensure user is authenticated

## Next Steps

1. ✅ Set up Firebase project
2. ✅ Configure Android and Desktop apps
3. ✅ Enable Firestore and Authentication
4. ⏭️ Implement Firestore service layer
5. ⏭️ Migrate from Hive to Firestore
6. ⏭️ Test offline functionality

For implementation details, see the migration guide.
