import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:keystone/models/task.dart';

/// Service for syncing events to Google Calendar
class GoogleCalendarService {
  calendar.CalendarApi? _calendarApi;

  /// Initialize with an authenticated HTTP client
  void initialize(http.Client? client) {
    if (client != null) {
      _calendarApi = calendar.CalendarApi(client);
    }
  }

  /// Check if the service is initialized and ready to use
  bool get isInitialized => _calendarApi != null;

  /// Add a task event to Google Calendar
  /// Returns the created event ID if successful, null otherwise
  Future<String?> addEventToCalendar(Task task) async {
    if (!isInitialized) {
      throw Exception('Google Calendar service not initialized');
    }

    try {
      // Create start of day DateTime
      final startDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      // Create a Google Calendar event from the task
      final event = calendar.Event();
      event.summary = task.text;

      if (task.note?.isNotEmpty == true) {
        event.description = task.note;
      }

      // Add tags to the description if present
      if (task.tags.isNotEmpty) {
        final tagsString = '\n\nTags: ${task.tags.join(' ')}';
        event.description = (event.description ?? '') + tagsString;
      }

      // Set as all-day event using dateTime
      event.start = calendar.EventDateTime();
      event.start!.dateTime = startDate;

      event.end = calendar.EventDateTime();
      event.end!.dateTime = startDate.add(const Duration(hours: 1));

      // Add to primary calendar
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');

      return createdEvent.id;
    } catch (e) {
      print('Error adding event to Google Calendar: $e');
      return null;
    }
  }

  /// Update an existing Google Calendar event
  Future<bool> updateEventInCalendar(String eventId, Task task) async {
    if (!isInitialized) {
      throw Exception('Google Calendar service not initialized');
    }

    try {
      // Create start of day DateTime
      final startDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      // Create updated event
      final event = calendar.Event();
      event.summary = task.text;

      if (task.note?.isNotEmpty == true) {
        event.description = task.note;
      }

      // Add tags to the description if present
      if (task.tags.isNotEmpty) {
        final tagsString = '\n\nTags: ${task.tags.join(' ')}';
        event.description = (event.description ?? '') + tagsString;
      }

      // Set as all-day event
      event.start = calendar.EventDateTime();
      event.start!.dateTime = startDate;

      event.end = calendar.EventDateTime();
      event.end!.dateTime = startDate.add(const Duration(hours: 1));

      // Update the event
      await _calendarApi!.events.update(event, 'primary', eventId);

      return true;
    } catch (e) {
      print('Error updating event in Google Calendar: $e');
      return false;
    }
  }

  /// Delete an event from Google Calendar
  Future<bool> deleteEventFromCalendar(String eventId) async {
    if (!isInitialized) {
      throw Exception('Google Calendar service not initialized');
    }

    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      print('Error deleting event from Google Calendar: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _calendarApi = null;
  }
}
