import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/models/journal_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/providers/sync_provider.dart';

final journalEntryListProvider =
    StateNotifierProvider<JournalEntryListNotifier, List<JournalEntry>>((ref) {
      return JournalEntryListNotifier(ref);
    });

class JournalEntryListNotifier extends StateNotifier<List<JournalEntry>> {
  final Box<JournalEntry> _box = Hive.box<JournalEntry>('journal_entries');
  final Ref _ref;
  
  JournalEntryListNotifier(this._ref) : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    state = entries;
  }

  void reload() {
    _loadEntries();
  }

  Future<void> _triggerAutoSync() async {
    try {
      await _ref.read(syncNotifierProvider.notifier).changeSync();
    } catch (e) {
      // Silently fail - auto-sync is best-effort
    }
  }

  void addJournalEntry(
    String body, {
    List<String>? imagePaths,
    String? tags,
  }) async {
    final entry = JournalEntry()
      ..body = body
      ..creationDate = DateTime.now()
      ..imagePaths = imagePaths ?? []
      ..tags = tags?.split(' ').where((t) => t.startsWith('#')).toList() ?? [];

    await _box.add(entry);
    state = [entry, ...state];
    await _triggerAutoSync();
  }

  void updateJournalEntry(
    JournalEntry entry,
    String newBody, {
    String? newTags,
  }) async {
    entry.body = newBody;
    entry.tags =
        newTags?.split(' ').where((t) => t.startsWith('#')).toList() ?? [];
    await entry.save();
    state = [
      for (final e in state)
        if (e.key == entry.key) entry else e,
    ];
    await _triggerAutoSync();
  }

  void addImageToJournalEntry(JournalEntry entry, String imagePath) async {
    entry.imagePaths.add(imagePath);
    await entry.save();
    state = [
      for (final e in state)
        if (e.key == entry.key) entry else e,
    ];
    await _triggerAutoSync();
  }

  void deleteJournalEntry(JournalEntry entry) async {
    await entry.delete();
    state = state.where((e) => e.key != entry.key).toList();
    await _triggerAutoSync();
  }
}
