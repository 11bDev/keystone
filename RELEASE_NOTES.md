# Keystone v0.0.1 Release Notes

**Release Date:** October 29, 2025

This is the initial release of Keystone, a cross-platform productivity app implementing the Bullet Journal methodology.

## 📦 Downloads

- **Android APK:** `keystone_0.0.1.apk` (54 MB)
- **Linux Debian Package:** `keystone_0.0.1_amd64.deb` (16 MB)

## ✨ Features

### Task Management
- ✅ Bullet Journal-style task tracking
- ✅ Task and Event categories
- ✅ Task states: pending, done, migrated, canceled
- ✅ Task migration to new dates
- ✅ Undo cancel functionality
- ✅ Optional notes on tasks
- ✅ Tag-based organization with hashtags
- ✅ Long-press context menu on mobile
- ✅ Overdue task highlighting

### Note Taking
- ✅ Quick note creation
- ✅ Optional titles
- ✅ Multi-line content
- ✅ Tag-based organization
- ✅ Automatic timestamps

### Journal
- ✅ Daily journal entries
- ✅ Image attachment support (mobile)
- ✅ Tag-based organization
- ✅ Timeline view
- ✅ Rich text entries

### Calendar View
- ✅ Integrated calendar with all data types
- ✅ Event markers for days with items
- ✅ Grouped display by type
- ✅ Interactive task management
- ✅ Visual indicators for overdue tasks

### Sync & Storage
- ✅ Google Drive automatic backup
- ✅ Manual sync options
- ✅ Backup restore on new device
- ✅ Platform-specific authentication (mobile & desktop)
- ✅ Local-first data storage with Hive

### User Interface
- ✅ Material Design 3
- ✅ Dark mode support (follows system)
- ✅ Responsive dialogs optimized for mobile
- ✅ Scrollable content
- ✅ Toast notifications

## 🔧 Installation

### Android
1. Download `keystone_0.0.1.apk`
2. Enable "Install from unknown sources" in settings
3. Open the APK file to install
4. Launch Keystone

**Requirements:** Android 5.0 (API 21) or higher

### Linux (Debian/Ubuntu)
```bash
sudo dpkg -i keystone_0.0.1_amd64.deb
sudo apt-get install -f
```

**Requirements:** Ubuntu 22.04+ or equivalent, GTK 3.0+

## 🐛 Known Issues

1. Desktop OAuth requires manual setup on first launch
2. Image picker not implemented for Linux desktop journal entries
3. Auto-sync interval fixed at 5 minutes (not user-configurable)
4. No search functionality across data types yet

## 📋 Minimum Requirements

### Android
- OS: Android 5.0 (Lollipop, API 21) or higher
- RAM: 2GB recommended
- Storage: 20MB free space

### Linux
- OS: Ubuntu 22.04+ or equivalent Debian-based distribution
- Libraries: GTK 3.0+, GLib 2.0
- RAM: 2GB recommended
- Storage: 50MB free space

## 🔐 Permissions

### Android
- **Internet:** Required for Google Drive sync
- **Storage:** Required for database and images
- **Camera:** Optional, for journal photo attachments

### Linux
- **Network:** Required for Google Drive sync
- **File System:** Required for database and OAuth tokens

## 🎯 Getting Started

1. Launch the app
2. Go to Settings (gear icon)
3. Sign in to Google Drive
4. Choose to restore existing backup or start fresh
5. Start creating tasks, notes, and journal entries!

## 📝 Changelog

### New Features
- Initial implementation of Bullet Journal task management
- Note-taking system with tags
- Journal entries with image support
- Integrated calendar view
- Google Drive synchronization
- Material Design 3 UI
- Dark mode support
- Long-press context menus
- Responsive dialogs
- Tag-based organization

### Technical Details
- **Flutter Version:** 3.x
- **Dart Version:** 3.x
- **State Management:** Riverpod 2.6.1
- **Database:** Hive 2.2.3
- **Cloud Sync:** Google Drive API v3
- **Calendar:** table_calendar 3.1.2

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Inspired by [Bullet Journal](https://bulletjournal.com)
- Icons from Material Design Icons

## 🤝 Contributing

Contributions are welcome! See README.md for development setup instructions.

## 📄 License

MIT License - See LICENSE file for details

## 💬 Support

For issues or questions, please open an issue on GitHub.

---

**Full Changelog**: Initial release
