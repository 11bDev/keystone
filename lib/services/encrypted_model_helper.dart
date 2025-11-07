import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:keystone/services/encryption_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to encrypt/decrypt models before Firestore sync
class EncryptedModelHelper {
  final EncryptionService _encryptionService;

  EncryptedModelHelper(this._encryptionService);

  // ==================== TASK ENCRYPTION ====================

  /// Encrypt Task data before sending to Firestore
  Map<String, dynamic> encryptTask(Task task) {
    final data = task.toFirestore();
    
    // Encrypt sensitive fields
    data['text'] = _encryptionService.encryptString(data['text'] as String?);
    data['note'] = _encryptionService.encryptString(data['note'] as String?);
    data['tags'] = _encryptionService.encryptStringList(
      List<String>.from(data['tags'] ?? [])
    );
    
    // Add encryption marker
    data['_encrypted'] = true;
    
    return data;
  }

  /// Decrypt Task data from Firestore
  Task decryptTask(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Check if data is encrypted
    if (data['_encrypted'] == true) {
      // Decrypt before parsing
      final decryptedData = Map<String, dynamic>.from(data);
      decryptedData['text'] = _encryptionService.decryptString(data['text'] as String?);
      decryptedData['note'] = _encryptionService.decryptString(data['note'] as String?);
      decryptedData['tags'] = _encryptionService.decryptStringList(
        List<String>.from(data['tags'] ?? [])
      );
      
      // Create modified doc
      final task = Task();
      task.id = doc.id;
      task.text = decryptedData['text'] as String;
      task.status = decryptedData['status'] as String? ?? 'pending';
      task.dueDate = (decryptedData['dueDate'] as Timestamp).toDate();
      task.tags = List<String>.from(decryptedData['tags'] as List? ?? []);
      task.category = decryptedData['category'] as String? ?? 'task';
      task.note = decryptedData['note'] as String?;
      task.googleCalendarEventId = decryptedData['googleCalendarEventId'] as String?;
      task.lastModified = decryptedData['lastModified'] != null 
          ? (decryptedData['lastModified'] as Timestamp).toDate()
          : null;
      task.eventStartTime = decryptedData['eventStartTime'] != null
          ? (decryptedData['eventStartTime'] as Timestamp).toDate()
          : null;
      task.eventEndTime = decryptedData['eventEndTime'] != null
          ? (decryptedData['eventEndTime'] as Timestamp).toDate()
          : null;
      return task;
    }
    
    // Not encrypted, parse normally
    return Task.fromFirestore(doc);
  }

  // ==================== NOTE ENCRYPTION ====================

  /// Encrypt Note data before sending to Firestore
  Map<String, dynamic> encryptNote(Note note) {
    final data = note.toFirestore();
    
    // Encrypt sensitive fields
    data['title'] = _encryptionService.encryptString(data['title'] as String?);
    data['content'] = _encryptionService.encryptString(data['content'] as String?);
    data['tags'] = _encryptionService.encryptStringList(
      List<String>.from(data['tags'] ?? [])
    );
    
    // Add encryption marker
    data['_encrypted'] = true;
    
    return data;
  }

  /// Decrypt Note data from Firestore
  Note decryptNote(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Check if data is encrypted
    if (data['_encrypted'] == true) {
      // Decrypt before parsing
      final decryptedData = Map<String, dynamic>.from(data);
      decryptedData['title'] = _encryptionService.decryptString(data['title'] as String?);
      decryptedData['content'] = _encryptionService.decryptString(data['content'] as String?);
      decryptedData['tags'] = _encryptionService.decryptStringList(
        List<String>.from(data['tags'] ?? [])
      );
      
      // Create modified doc - manual parsing
      final note = Note();
      note.id = doc.id;
      note.title = decryptedData['title'] as String? ?? '';
      note.content = decryptedData['content'] as String? ?? '';
      note.creationDate = (decryptedData['creationDate'] as Timestamp).toDate();
      note.tags = List<String>.from(decryptedData['tags'] as List? ?? []);
      note.lastModified = decryptedData['lastModified'] != null 
          ? (decryptedData['lastModified'] as Timestamp).toDate()
          : null;
      return note;
    }
    
    // Not encrypted, parse normally
    return Note.fromFirestore(doc);
  }

  // ==================== JOURNAL ENTRY ENCRYPTION ====================

  /// Encrypt JournalEntry data before sending to Firestore
  Map<String, dynamic> encryptJournalEntry(JournalEntry entry) {
    final data = entry.toFirestore();
    
    // Encrypt sensitive fields
    data['content'] = _encryptionService.encryptString(data['content'] as String?);
    data['tags'] = _encryptionService.encryptStringList(
      List<String>.from(data['tags'] ?? [])
    );
    
    // Add encryption marker
    data['_encrypted'] = true;
    
    return data;
  }

  /// Decrypt JournalEntry data from Firestore
  JournalEntry decryptJournalEntry(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Check if data is encrypted
    if (data['_encrypted'] == true) {
      // Decrypt before parsing
      final decryptedData = Map<String, dynamic>.from(data);
      decryptedData['content'] = _encryptionService.decryptString(data['content'] as String?);
      decryptedData['tags'] = _encryptionService.decryptStringList(
        List<String>.from(data['tags'] ?? [])
      );
      
      // Create modified doc - manual parsing
      final entry = JournalEntry();
      entry.id = doc.id;
      entry.content = decryptedData['content'] as String? ?? '';
      entry.creationDate = (decryptedData['creationDate'] as Timestamp).toDate();
      entry.tags = List<String>.from(decryptedData['tags'] as List? ?? []);
      entry.lastModified = decryptedData['lastModified'] != null 
          ? (decryptedData['lastModified'] as Timestamp).toDate()
          : null;
      return entry;
    }
    
    // Not encrypted, parse normally
    return JournalEntry.fromFirestore(doc);
  }
}
