import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/services/sync_service_interface.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile-compatible Google Drive sync using native Google Sign-In
class SyncService implements SyncServiceInterface {
  static final sign_in.GoogleSignIn _googleSignIn = sign_in.GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;
  http.Client? _authenticatedClient;

  static const String _backupFileName = 'keystone_backup.json';
  static const String _backupFolderName = 'Keystone';

  /// Initialize and sign in to Google using native Google Sign-In
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('User cancelled sign-in');
        return false;
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      
      if (accessToken == null) {
        print('Failed to get access token');
        return false;
      }

      // Create authenticated client
      _authenticatedClient = _GoogleAuthClient(accessToken, auth);
      _driveApi = drive.DriveApi(_authenticatedClient!);

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

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authenticatedClient?.close();
    _authenticatedClient = null;
    _driveApi = null;
    print('Signed out from Google Drive');
  }

  /// Check if user is signed in
  @override
  bool get isSignedIn => _googleSignIn.currentUser != null && _driveApi != null;

  /// Get user email
  @override
  String? get userEmail => _googleSignIn.currentUser?.email;

  /// Sync data to Google Drive (alias for uploadBackup)
  @override
  Future<void> syncToGoogleDrive() => uploadBackup();

  /// Sync data from Google Drive (alias for downloadBackup)
  @override
  Future<void> syncFromGoogleDrive() => downloadBackup();

  /// Export to local file (returns file path)
  @override
  Future<String> exportToLocalFile() async {
    final file = await exportToFile();
    return file.path;
  }

  /// Import from local file path
  @override
  Future<void> importFromLocalFile(String filePath) async {
    await importFromFile(File(filePath));
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
  Future<void> uploadBackup() async {
    if (!isSignedIn) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      print('Starting backup upload...');
      final folderId = await _getOrCreateAppFolder();
      print('Got app folder ID: $folderId');

      // Export data
      final data = await _exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      print('Exported data: ${jsonString.length} bytes');

      // Check if backup file already exists
      final existingFiles = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      final media = drive.Media(
        Stream.value(utf8.encode(jsonString)),
        jsonString.length,
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file (don't set parents field for updates)
        print('Updating existing backup file...');
        final driveFile = drive.File()..name = _backupFileName;
        
        await _driveApi!.files.update(
          driveFile,
          existingFiles.files!.first.id!,
          uploadMedia: media,
        );
        print('Backup updated successfully');
      } else {
        // Create new file (set parents field only for new files)
        print('Creating new backup file...');
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = [folderId];
        
        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        print('Backup created successfully');
      }
    } catch (e, stackTrace) {
      print('Error uploading backup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download backup from Google Drive
  Future<void> downloadBackup() async {
    if (!isSignedIn) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      print('Starting backup download...');
      final folderId = await _getOrCreateAppFolder();
      print('Got app folder ID: $folderId');

      // Find backup file
      final response = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      if (response.files == null || response.files!.isEmpty) {
        throw Exception('No backup found in Google Drive');
      }

      final fileId = response.files!.first.id!;
      print('Found backup file: $fileId');

      // Download file content
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the media content
      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      final jsonString = utf8.decode(dataStore);
      print('Downloaded ${jsonString.length} bytes');
      final data = json.decode(jsonString);

      // Import the data
      await _importData(data);
      print('Backup downloaded and imported successfully');
    } catch (e, stackTrace) {
      print('Error downloading backup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get last backup time from Google Drive
  Future<DateTime?> getLastBackupTime() async {
    if (!isSignedIn) return null;

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
    } catch (e) {
      print('Error getting last backup time: $e');
    }
    return null;
  }

  /// Export data to local file
  Future<File> exportToFile() async {
    final data = await _exportData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/keystone_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    return file;
  }

  /// Import data from local file
  Future<void> importFromFile(File file) async {
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    await _importData(data);
  }
}

/// Simple HTTP client that adds Bearer token to requests
class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._accessToken, sign_in.GoogleSignInAuthentication auth);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
