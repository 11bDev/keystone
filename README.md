# Keystone

A cross-platform productivity app built with Flutter, implementing the Bullet Journal methodology for task management, note-taking, and journaling with automatic Google Drive sync.

![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Web-lightgrey.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)

## Features

### �� Bullet Journal Task Management
- **Task Categories**: Organize tasks as regular tasks or events
- **Task States**: Track tasks as pending, done, migrated, or canceled
- **Task Migration**: Easily move tasks to new dates
- **Undo Cancel**: Restore canceled tasks back to pending state
- **Notes**: Add optional notes to any task
- **Tags**: Organize tasks with hashtag-based tagging (#work, #personal, etc.)
- **Visual Indicators**: Different icons for task states (bullet points, checkmarks, arrows, slashes)
- **Overdue Highlighting**: Past-due pending tasks highlighted in red on calendar view
- **Long-press Context Menu**: Quick access to edit, migrate, cancel/undo, and delete on mobile

### �� Note Taking
- **Quick Notes**: Create notes with optional titles
- **Rich Content**: Support for multi-line content
- **Tags**: Organize notes with hashtag-based tagging
- **Search & Filter**: Find notes by tags or content
- **Timestamps**: Automatic creation date tracking

### 📖 Journal Entries
- **Daily Journaling**: Record daily thoughts and experiences
- **Image Support**: Attach images from your device gallery
- **Tags**: Organize journal entries with hashtags
- **Timeline View**: Browse entries chronologically
- **Rich Text**: Multi-line journal body with optional tags

### 📅 Calendar View
- **Integrated Calendar**: View all tasks, notes, and journal entries in one place
- **Event Markers**: Visual indicators for days with items
- **Grouped Display**: Items organized by type (Tasks, Notes, Journal Entries)
- **Interactive**: Long-press tasks for quick actions
- **Overdue Visualization**: Pending tasks on past dates shown with red background

### ☁️ Google Drive Sync
- **Automatic Backup**: Auto-sync to Google Drive at regular intervals
- **Manual Sync**: Push/pull data on demand
- **Conflict Resolution**: Choose between existing backup or fresh start on new device
- **Platform Support**: Works on both mobile (Google Sign-In) and desktop (OAuth 2.0)
- **Privacy**: All data stored in your personal Google Drive

### 🎨 User Interface
- **Material Design 3**: Modern, clean interface following latest Material Design guidelines
- **Dark Mode Support**: Automatic theme switching based on system preferences
- **Responsive Dialogs**: Optimized input dialogs that utilize phone screen width
- **Scrollable Content**: All dialogs handle keyboard display gracefully
- **Toast Notifications**: Informative feedback for sync operations

## Installation

### Android

Download the latest \`.apk\` from the [Releases](../../releases) page and install on your Android device.

**Minimum Requirements:**
- Android 5.0 (API 21) or higher
- ~20MB storage space

### Linux (Debian/Ubuntu)

Download the latest \`.deb\` package from the [Releases](../../releases) page and install:

\`\`\`bash
sudo dpkg -i keystone_0.0.1_amd64.deb
sudo apt-get install -f  # Install dependencies if needed
\`\`\`

**Minimum Requirements:**
- Ubuntu 22.04+ or equivalent Debian-based distribution
- GTK 3.0+
- ~50MB storage space

### Building from Source

#### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- For Android: Android Studio with Android SDK
- For Linux: GTK development libraries
- Dart 3.0+

#### Clone and Build

\`\`\`bash
# Clone the repository
git clone https://github.com/yourusername/keystone.git
cd keystone

# Install dependencies
flutter pub get

# Generate code (for Hive models)
dart run build_runner build --delete-conflicting-outputs

# Run on your device
flutter run

# Or build for specific platforms
flutter build apk          # Android APK
flutter build linux        # Linux desktop
flutter build web          # Web application
\`\`\`

## Usage

### First Launch

1. **Launch the app** on your device
2. **Navigate to Settings** (gear icon in the app bar)
3. **Sign in to Google Drive** to enable automatic sync
4. **Choose** whether to restore existing backup or start fresh

### Creating Tasks

1. Navigate to the **Tasks** tab
2. Tap the **+** button
3. Select task type: **Task** or **Event**
4. Enter task description
5. Add optional tags (e.g., \`#work #urgent\`)
6. Add optional note for additional context
7. Select due date
8. Tap **Add**

### Managing Tasks

- **Tap** a task to toggle between pending and done
- **Long-press** a task to open context menu with options:
  - Edit task details
  - Migrate to new date
  - Cancel task (with option to undo later)
  - Delete task permanently
- **Swipe menu** (three-dot icon) provides same options

### Taking Notes

1. Navigate to the **Notes** tab
2. Tap the **+** button
3. Add optional title
4. Enter note content
5. Add tags if desired
6. Tap **Add**

### Journal Entries

1. Navigate to the **Journal** tab
2. Tap the **+** button
3. Write your journal entry
4. Optionally add tags
5. Optionally attach images using **Insert Picture** button
6. Tap **Add**

### Calendar View

1. Navigate to the **Calendar** tab
2. Browse days by swiping or tapping dates
3. View all items for selected day grouped by type
4. Long-press tasks for quick actions
5. Days with pending overdue tasks shown in red

### Google Drive Sync

**Configure Sync:**
1. Go to **Settings**
2. Tap **Sign in to Google Drive**
3. Authorize the app with your Google account
4. Enable **Auto Sync** for automatic backups

**Manual Sync:**
- Tap **Sync to Google Drive** to push current data
- Tap **Sync from Google Drive** to pull latest backup

**Sync Frequency:**
- Auto-sync runs every 5 minutes when enabled
- Manual sync available anytime in Settings

## Architecture

### Technology Stack
- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **State Management**: Riverpod 2.6.1
- **Local Database**: Hive 2.2.3
- **Cloud Sync**: Google Drive API v3
- **Authentication**: 
  - Mobile: google_sign_in 6.2.2
  - Desktop: googleapis_auth 1.6.0
- **Calendar**: table_calendar 3.1.2
- **Image Picking**: image_picker 1.1.2

### Project Structure

\`\`\`
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (Hive)
│   ├── task.dart
│   ├── note.dart
│   └── journal_entry.dart
├── providers/                # Riverpod state providers
│   ├── task_provider.dart
│   ├── note_provider.dart
│   ├── journal_provider.dart
│   └── settings_provider.dart
├── services/                 # Business logic services
│   ├── sync_service.dart
│   ├── sync_service_mobile.dart
│   └── sync_service_desktop.dart
├── features/                 # Feature modules
│   ├── tasks/
│   │   └── tasks_tab.dart
│   ├── notes/
│   │   └── notes_tab.dart
│   ├── journal/
│   │   ├── journal_tab.dart
│   │   └── journal_detail_screen.dart
│   ├── calendar/
│   │   └── calendar_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── theme.dart                # App theming
\`\`\`

### Data Storage

- **Local Storage**: Hive NoSQL database stored in app documents directory
- **Cloud Backup**: JSON export synced to Google Drive (\`keystone_backup.json\`)
- **Image Storage**: Journal images stored locally in app directory

### Sync Mechanism

1. **Auto-sync**: Periodic timer triggers sync when enabled
2. **Manual sync**: User-initiated push/pull operations
3. **Data Format**: JSON serialization of all tasks, notes, and journal entries
4. **Conflict Resolution**: User chooses on first sync after installation
5. **Platform-specific**: Different auth flows for mobile vs desktop

## Privacy & Security

- **Local-first**: All data stored locally on your device
- **Your Google Drive**: Backups stored in your personal Google Drive account
- **No Analytics**: No usage tracking or analytics collection
- **No Ads**: Completely ad-free experience
- **Open Source**: Full source code available for review

## Permissions

### Android
- **Internet**: Required for Google Drive sync
- **Storage**: Required for local database and image attachments
- **Camera** (optional): For attaching photos to journal entries

### Linux
- **Network**: Required for Google Drive sync
- **File System**: Required for local database and OAuth token storage

## Roadmap

- [ ] Dark mode toggle (currently follows system)
- [ ] Export to PDF/Markdown
- [ ] Recurring tasks
- [ ] Task priorities
- [ ] Search functionality across all data types
- [ ] Desktop file picker for journal images
- [ ] Encryption for local database
- [ ] Multiple Google accounts support
- [ ] Task templates
- [ ] Statistics and insights
- [ ] iOS support
- [ ] Windows support
- [ ] macOS support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (\`git checkout -b feature/AmazingFeature\`)
3. Make your changes
4. Run tests (when available)
5. Commit your changes (\`git commit -m 'Add some AmazingFeature'\`)
6. Push to the branch (\`git push origin feature/AmazingFeature\`)
7. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use \`dart format\` before committing
- Add comments for complex logic
- Keep functions focused and small

## Known Issues

- Desktop version requires manual OAuth setup on first launch
- Image picker not yet implemented for Linux desktop
- Auto-sync interval is fixed at 5 minutes (not configurable)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Inspired by [Bullet Journal](https://bulletjournal.com) methodology
- Calendar component by [table_calendar](https://pub.dev/packages/table_calendar)
- Icons from [Material Design Icons](https://fonts.google.com/icons)

## Support

For issues, questions, or suggestions, please [open an issue](../../issues) on GitHub.

## Changelog

### Version 0.0.1 (Initial Release)
- Basic task management with Bullet Journal methodology
- Note-taking functionality
- Journal entries with image support
- Calendar view with integrated timeline
- Google Drive sync (mobile and desktop)
- Material Design 3 UI
- Dark mode support
- Task migration and status management
- Tag-based organization
- Long-press context menus on mobile
- Undo cancel functionality
- Responsive dialogs optimized for mobile screens
