import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/services/sync_service_interface.dart';
import 'package:keystone/services/google_calendar_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop-compatible Google Drive sync using OAuth 2.0
class SyncService implements SyncServiceInterface {
  // OAuth 2.0 credentials from Google Cloud Console
  // Set via environment variables: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET
  static const String _clientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: 'YOUR_CLIENT_ID.apps.googleusercontent.com');
  static const String _clientSecret = 
      String.fromEnvironment('GOOGLE_CLIENT_SECRET', defaultValue: 'YOUR_CLIENT_SECRET');

  static final ClientId _credentials = ClientId(_clientId, _clientSecret);
  static final List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    calendar.CalendarApi.calendarScope,
  ];

  AccessCredentials? _accessCredentials;
  drive.DriveApi? _driveApi;
  http.Client? _authenticatedClient;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  static const String _backupFileName = 'keystone_backup.json';
  static const String _backupFolderName = 'Keystone';
  
  /// Get the calendar service instance
  @override
  GoogleCalendarService get calendarService => _calendarService;

  /// Initialize and sign in to Google using OAuth 2.0 desktop flow
  Future<bool> signIn() async {
    try {
      // Use desktop OAuth flow with local redirect
      _authenticatedClient = await clientViaUserConsent(
        _credentials,
        _scopes,
        _promptUserForConsent,
      );

      // Extract credentials for storage/reuse
      if (_authenticatedClient is AutoRefreshingAuthClient) {
        _accessCredentials =
            (_authenticatedClient as AutoRefreshingAuthClient).credentials;
      }

      // Initialize Drive API
      _driveApi = drive.DriveApi(_authenticatedClient!);
      
      // Initialize Calendar service
      _calendarService.initialize(_authenticatedClient);

      print('Successfully signed in to Google Drive!');
      return true;
    } catch (error) {
      print('Error signing in: $error');
      _authenticatedClient?.close();
      _authenticatedClient = null;
      _driveApi = null;
      return false;
    }
  }

  /// Prompt user to sign in via browser (OAuth 2.0 consent flow)
  Future<void> _promptUserForConsent(String url) async {
    print('Opening browser for Google sign-in...');
    print('URL: $url');

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch browser automatically.');
      print('Please manually open this URL in your browser:');
      print(url);
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    _authenticatedClient?.close();
    _authenticatedClient = null;
    _accessCredentials = null;
    _driveApi = null;
    print('Signed out from Google Drive');
  }

  /// Check if user is signed in
  bool get isSignedIn => _authenticatedClient != null && _driveApi != null;

  /// Get a simple identifier (not actual email, but usable for display)
  String? get userEmail {
    if (_accessCredentials != null) {
      return 'Google Account (Connected)';
    }
    return null;
  }

  /// Export all Hive data to JSON
  Future<Map<String, dynamic>> _exportData() async {
    final tasksBox = Hive.box<Task>('tasks');
    final notesBox = Hive.box<Note>('notes');
    final journalBox = Hive.box<JournalEntry>('journal_entries');

    final tasks = tasksBox.values.toList();
    final notes = notesBox.values.toList();
    final journalEntries = journalBox.values.toList();

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'tasks': tasks
          .map(
            (task) => {
              'text': task.text,
              'status': task.status,
              'dueDate': task.dueDate.toIso8601String(),
              'tags': task.tags,
              'category': task.category,
              'note': task.note,
            },
          )
          .toList(),
      'notes': notes
          .map(
            (note) => {
              'content': note.content,
              'optionalTitle': note.optionalTitle,
              'tags': note.tags,
              'creationDate': note.creationDate.toIso8601String(),
            },
          )
          .toList(),
      'journalEntries': journalEntries
          .map(
            (entry) => {
              'body': entry.body,
              'tags': entry.tags,
              'creationDate': entry.creationDate.toIso8601String(),
              'imagePaths': entry.imagePaths,
            },
          )
          .toList(),
    };
  }

  /// Import JSON data into Hive
  Future<void> _importData(Map<String, dynamic> data) async {
    final tasksBox = Hive.box<Task>('tasks');
    final notesBox = Hive.box<Note>('notes');
    final journalBox = Hive.box<JournalEntry>('journal_entries');

    // Clear existing data
    await tasksBox.clear();
    await notesBox.clear();
    await journalBox.clear();

    // Import tasks
    for (final taskData in (data['tasks'] as List)) {
      final task = Task()
        ..text = taskData['text']
        ..status = taskData['status']
        ..dueDate = DateTime.parse(taskData['dueDate'])
        ..tags = List<String>.from(taskData['tags'])
        ..category = taskData['category']
        ..note = taskData['note'];
      await tasksBox.add(task);
    }

    // Import notes
    for (final noteData in (data['notes'] as List)) {
      final note = Note()
        ..content = noteData['content']
        ..optionalTitle = noteData['optionalTitle']
        ..tags = List<String>.from(noteData['tags'])
        ..creationDate = DateTime.parse(noteData['creationDate']);
      await notesBox.add(note);
    }

    // Import journal entries
    for (final entryData in (data['journalEntries'] as List)) {
      final entry = JournalEntry()
        ..body = entryData['body']
        ..tags = List<String>.from(entryData['tags'])
        ..creationDate = DateTime.parse(entryData['creationDate'])
        ..imagePaths = List<String>.from(entryData['imagePaths'] ?? []);
      await journalBox.add(entry);
    }
  }

  /// Find or create the app folder in Google Drive
  Future<String> _getOrCreateAppFolder() async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    // Search for existing folder
    final response = await _driveApi!.files.list(
      q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    // Create folder if it doesn't exist
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id!;
  }

  /// Upload backup to Google Drive
  Future<void> syncToGoogleDrive() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      print('Starting backup to Google Drive...');

      // Export data
      final data = await _exportData();
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      // Get app folder
      final folderId = await _getOrCreateAppFolder();

      // Check if backup file already exists
      final existingFiles = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file - don't set parents in update requests
        final updateFile = drive.File()
          ..name = _backupFileName;
        
        await _driveApi!.files.update(
          updateFile,
          existingFiles.files!.first.id!,
          uploadMedia: media,
        );
        print('Updated existing backup in Google Drive');
      } else {
        // Create new file - parents can only be set during creation
        final createFile = drive.File()
          ..name = _backupFileName
          ..parents = [folderId];
        
        await _driveApi!.files.create(createFile, uploadMedia: media);
        print('Created new backup in Google Drive');
      }

      print('✅ Backup uploaded to Google Drive successfully');
    } catch (error) {
      print('❌ Error uploading to Google Drive: $error');
      rethrow;
    }
  }

  /// Download and restore backup from Google Drive
  Future<void> syncFromGoogleDrive() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      print('Starting restore from Google Drive...');

      // Get app folder
      final folderId = await _getOrCreateAppFolder();

      // Find backup file
      final response = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        throw Exception('No backup found in Google Drive');
      }

      final fileId = response.files!.first.id!;

      // Download file
      final media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import data
      await _importData(data);

      print('✅ Backup restored from Google Drive successfully');
    } catch (error) {
      print('❌ Error downloading from Google Drive: $error');
      rethrow;
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    if (_driveApi == null) return null;

    try {
      final folderId = await _getOrCreateAppFolder();
      final response = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.modifiedTime;
      }
    } catch (error) {
      print('Error getting last backup time: $error');
    }

    return null;
  }

  /// Export data to local JSON file (no Google account needed)
  Future<String> exportToLocalFile() async {
    try {
      final data = await _exportData();
      final jsonString = jsonEncode(data);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final file = File('${directory.path}/keystone_backup_$timestamp.json');

      await file.writeAsString(jsonString);
      print('✅ Exported to: ${file.path}');
      return file.path;
    } catch (error) {
      print('❌ Error exporting to local file: $error');
      rethrow;
    }
  }

  /// Import data from local JSON file
  Future<void> importFromLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      await _importData(data);
      print('✅ Data imported from local file successfully');
    } catch (error) {
      print('❌ Error importing from local file: $error');
      rethrow;
    }
  }
}
