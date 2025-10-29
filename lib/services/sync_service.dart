import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SyncService {
  // TODO: Replace with your own OAuth 2.0 credentials from Google Cloud Console
  // For development, you can use these placeholders, but you MUST create your own:
  // 1. Go to https://console.cloud.google.com/
  // 2. Create a project and enable Google Drive API
  // 3. Create OAuth 2.0 credentials (Desktop app type)
  // 4. Download the credentials and extract client_id and client_secret
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';

  static final ClientId _credentials = ClientId(_clientId, _clientSecret);
  static final List<String> _scopes = [drive.DriveApi.driveFileScope];

  AccessCredentials? _accessCredentials;
  drive.DriveApi? _driveApi;
  http.Client? _authenticatedClient;

  static const String _backupFileName = 'keystone_backup.json';
  static const String _backupFolderName = 'Keystone';

  /// Initialize and sign in to Google using OAuth 2.0 desktop flow
  Future<bool> signIn() async {
    try {
      // Check if credentials are configured
      if (_clientId == 'YOUR_CLIENT_ID.apps.googleusercontent.com') {
        print('Error: OAuth credentials not configured!');
        print('Please follow GOOGLE_DRIVE_SETUP.md to set up credentials');
        throw Exception(
          'OAuth credentials not configured. See GOOGLE_DRIVE_SETUP.md',
        );
      }

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

      return true;
    } catch (error) {
      print('Error signing in: $error');
      _authenticatedClient?.close();
      _authenticatedClient = null;
      _driveApi = null;
      return false;
    }
  }

  /// Prompt user to sign in via browser
  Future<void> _promptUserForConsent(String url) async {
    print('Please sign in using this URL:');
    print(url);

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch browser. Please manually open:');
      print(url);
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    _authenticatedClient?.close();
    _authenticatedClient = null;
    _accessCredentials = null;
    _driveApi = null;
  }

  /// Check if user is signed in
  bool get isSignedIn => _authenticatedClient != null && _driveApi != null;

  /// Get current user email (if available in credentials)
  String? get userEmail => _accessCredentials?.accessToken.data.toString();

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

      final file = drive.File()
        ..name = _backupFileName
        ..parents = [folderId];

      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        await _driveApi!.files.update(
          file,
          existingFiles.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        await _driveApi!.files.create(file, uploadMedia: media);
      }

      print('Backup uploaded to Google Drive successfully');
    } catch (error) {
      print('Error uploading to Google Drive: $error');
      rethrow;
    }
  }

  /// Download and restore backup from Google Drive
  Future<void> syncFromGoogleDrive() async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
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

      print('Backup restored from Google Drive successfully');
    } catch (error) {
      print('Error downloading from Google Drive: $error');
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
        $fields: 'files(modifiedTime)',
      );

      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.modifiedTime;
      }
    } catch (error) {
      print('Error getting last backup time: $error');
    }

    return null;
  }

  /// Export data to local JSON file (for platforms without Google Sign-In support)
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
      return file.path;
    } catch (error) {
      print('Error exporting to local file: $error');
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
      print('Data imported from local file successfully');
    } catch (error) {
      print('Error importing from local file: $error');
      rethrow;
    }
  }
}
