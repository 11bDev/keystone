# Google OAuth Credentials Setup

This directory contains OAuth credentials for Google Drive and Calendar API access.

## Quick Setup

1. **Copy the example file:**
   ```bash
   cp google_credentials.example.dart google_credentials.dart
   ```

2. **Get your credentials from Google Cloud Console:**
   - Go to https://console.cloud.google.com/
   - Select your project (or create one)
   - Enable **Google Drive API** and **Google Calendar API**
   - Create OAuth 2.0 credentials:
     - **For Desktop (Linux/Windows/macOS):** Application type = "Desktop app"
     - **For Mobile (Android):** Application type = "Android" (with SHA-1 fingerprint)

3. **Fill in your credentials in `google_credentials.dart`:**
   - Replace `YOUR_DESKTOP_CLIENT_ID` with your Desktop app Client ID
   - Replace `YOUR_DESKTOP_CLIENT_SECRET` with your Desktop app Client Secret
   - Replace `YOUR_MOBILE_CLIENT_ID` with your Android app Client ID

4. **The file is gitignored** - Your credentials will never be committed to git

## Detailed Instructions

See the main repository's `GOOGLE_SETUP.md` for complete step-by-step instructions on creating OAuth credentials in Google Cloud Console.

## Security Notes

- ✅ `google_credentials.dart` is gitignored - safe to add real credentials
- ✅ `google_credentials.example.dart` is tracked - contains only placeholders
- ⚠️ Never commit real credentials to version control
- ⚠️ Keep your Client Secret private
