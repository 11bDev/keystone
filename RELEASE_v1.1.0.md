# Keystone v1.1.0 Release Notes

Release date: October 30, 2025

## 🎉 What's New

### Google Calendar Integration
- **Bidirectional Sync**: Events now automatically sync with Google Calendar
- **Add to Calendar Option**: When creating events, choose to add them to Google Calendar
- **Automatic Updates**: Editing or migrating events updates them in Google Calendar
- **Seamless Deletion**: Deleting events removes them from Google Calendar too

### Enhanced User Interface
- **Responsive Calendar Layout**: 
  - Desktop: Side-by-side calendar and events view
  - Mobile: Vertical stacking for optimal screen usage
  - Calendar constrained to 500px max width on desktop
- **Collapsible Categories**: Calendar view now has expandable sections for Tasks, Notes, and Journal Entries
- **New Themes**: 
  - **Parchment Theme**: Beautiful serif fonts perfect for reading and writing
  - **Newspaper Theme**: Classic newsprint aesthetic (now the default!)
  - Total of 5 themes: Light, Dark, Sepia, Parchment, Newspaper

### Improved Task Management
- **Enhanced Future View**: Tasks grouped by month, then by date with full day names
- **Date Labels**: Display dates as "Monday the 21st" with proper ordinal suffixes
- **Notes Context Menu**: Long-press notes to edit or delete with confirmation
- **Settings Refresh**: Data properly refreshes after restore from Google Drive

### Bug Fixes
- Fixed Google Drive sync 403 error on desktop (parents field issue)
- Improved error handling for calendar sync operations
- Better state management after data restore

## 🔧 Technical Changes

### New Features
- Added `GoogleCalendarService` for Calendar API integration
- Extended Task model with `googleCalendarEventId` field
- OAuth scopes now include Google Calendar API access
- All task CRUD operations sync to Google Calendar when applicable

### Security Improvements
- **OAuth credentials moved to environment variables**
- Added `.env.example` template for easy setup
- Created comprehensive `GOOGLE_SETUP.md` guide
- Updated `.gitignore` to exclude sensitive credential files

### Breaking Changes
⚠️ **Desktop builds now require environment variables:**

```bash
flutter run -d linux \
  --dart-define=GOOGLE_CLIENT_ID=your-id \
  --dart-define=GOOGLE_CLIENT_SECRET=your-secret
```

See `GOOGLE_SETUP.md` for complete setup instructions.

## 📦 Installation

### Android (APK)
**File**: `keystone_1.1.0.apk` (54 MB)

**Requirements:**
- Android 5.0 (API 21) or higher
- ~60MB storage space

**Installation:**
1. Download `keystone_1.1.0.apk`
2. Enable "Install from Unknown Sources" in Android settings
3. Open the APK and install

### Linux (Debian/Ubuntu)
**File**: `keystone_1.1.0_amd64.deb` (31 MB)

**Requirements:**
- Ubuntu 22.04+ or equivalent Debian-based distribution
- GTK 3.0+
- ~80MB storage space

**Installation:**
```bash
sudo dpkg -i keystone_1.1.0_amd64.deb
sudo apt-get install -f  # Install dependencies if needed
```

## 🔐 File Verification

Verify your downloads using SHA256 checksums:

```
3f5a8ee99ed2748819c6e0a99f11bd8552e5103d98baee60f21cd1ee2b91bf5c  keystone_1.1.0.apk
b2b7ac4b160ad216b64e1af41aca9737f192b0b58dc6194a7ac975f093368517  keystone_1.1.0_amd64.deb
```

**Verify:**
```bash
sha256sum -c keystone_1.1.0_checksums.txt
```

## 🚀 Getting Started

### First-Time Setup

1. **Google OAuth Setup** (Required for sync features):
   - Follow the comprehensive guide in `GOOGLE_SETUP.md`
   - Set up OAuth credentials in Google Cloud Console
   - Configure for both desktop and mobile

2. **Initial Configuration**:
   - Launch the app
   - Go to Settings → Sign in to Google Drive
   - Choose to restore existing backup or start fresh
   - Enable Auto Sync for automatic backups

### Using Google Calendar Integration

1. **Creating Events**:
   - Go to Tasks tab → Add button
   - Select "Event" category
   - Check "Add to Google Calendar" option
   - Event will be created in your Google Calendar

2. **Managing Events**:
   - Edit: Updates sync to Google Calendar automatically
   - Migrate: Changes the event date in Google Calendar
   - Delete: Removes from both app and Google Calendar

## 📚 Documentation

- **GOOGLE_SETUP.md**: Complete OAuth setup guide
- **README.md**: Full application documentation
- **.env.example**: Template for environment variables

## 🐛 Known Issues

- Desktop version requires OAuth credentials via environment variables
- Image picker not yet implemented for Linux desktop journal entries
- Auto-sync interval is fixed at 5 minutes (not configurable)

## 🔄 Upgrading from v0.0.1

1. **Backup Your Data**: 
   - If using v0.0.1, ensure you've synced to Google Drive
   
2. **Install v1.1.0**:
   - Android: Simply install the new APK over the old one
   - Linux: Install the new DEB package (`sudo dpkg -i keystone_1.1.0_amd64.deb`)

3. **Reconfigure OAuth** (Desktop only):
   - Desktop builds now use environment variables
   - Update your OAuth credentials in Google Cloud Console
   - Run with `--dart-define` flags (see GOOGLE_SETUP.md)

4. **Restore Data**:
   - Sign in to Google Drive
   - Choose to restore existing backup
   - All your tasks, notes, and journal entries will be restored

## 🙏 Acknowledgments

Thank you to everyone who provided feedback on v0.0.1!

## 📝 Full Changelog

See the commit history for detailed changes:
- Google Calendar integration
- Responsive calendar layout with ExpansionTile
- Parchment and Newspaper themes
- Enhanced Future view with date grouping
- OAuth security improvements
- Bug fixes and stability improvements

---

**Previous Release**: [v0.0.1](https://github.com/11bDev/keystone/releases/tag/v0.0.1)
