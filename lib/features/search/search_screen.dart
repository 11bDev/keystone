import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keystone/providers/journal_provider.dart';
import 'package:keystone/providers/note_provider.dart';
import 'package:keystone/providers/search_provider.dart';
import 'package:keystone/providers/task_provider.dart';
import 'package:keystone/models/task.dart';
import 'package:keystone/models/note.dart';
import 'package:keystone/models/journal_entry.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchByTagsOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    _searchController.addListener(() {
      // Delay provider update to avoid modifying state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(searchQueryProvider.notifier).state = _searchController.text;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fuzzy match scoring - returns a score between 0 and 1
  double _fuzzyMatchScore(String text, String query) {
    if (query.isEmpty) return 0;

    text = text.toLowerCase();
    query = query.toLowerCase();

    // Exact match gets highest score
    if (text == query) return 1.0;

    // Contains gets high score
    if (text.contains(query)) {
      // Score based on position and length ratio
      final position = text.indexOf(query);
      final lengthRatio = query.length / text.length;
      final positionScore = 1 - (position / text.length);
      return 0.7 + (0.2 * lengthRatio) + (0.1 * positionScore);
    }

    // Character-by-character fuzzy matching
    int queryIndex = 0;
    int matchCount = 0;
    int consecutiveMatches = 0;
    double bonusScore = 0;

    for (int i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] == query[queryIndex]) {
        matchCount++;
        consecutiveMatches++;
        queryIndex++;
        // Bonus for consecutive character matches
        if (consecutiveMatches > 1) {
          bonusScore += 0.05 * consecutiveMatches;
        }
      } else {
        consecutiveMatches = 0;
      }
    }

    if (queryIndex == query.length) {
      // All query characters found
      final matchRatio = matchCount / query.length;
      final lengthPenalty =
          1 - ((text.length - query.length) / (text.length + query.length));
      return (0.3 * matchRatio + 0.2 * lengthPenalty + bonusScore).clamp(
        0.0,
        0.69,
      );
    }

    return 0; // No match
  }

  /// Check if tags match the query
  bool _tagsMatch(List<String> tags, String query) {
    if (query.isEmpty) return false;

    final queryLower = query.toLowerCase();

    // Direct tag match (with or without #)
    if (queryLower.startsWith('#')) {
      return tags.any((tag) => tag.toLowerCase() == queryLower);
    }

    // Match tag content without #
    return tags.any((tag) => tag.toLowerCase().contains('#$queryLower'));
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final tasks = ref.watch(taskListProvider);
    final notes = ref.watch(noteListProvider);
    final journalEntries = ref.watch(journalEntryListProvider);

    // Filter and score results
    List<({Task item, double score, String matchType})> scoredTasks = [];
    List<({Note item, double score, String matchType})> scoredNotes = [];
    List<({JournalEntry item, double score, String matchType})> scoredJournals =
        [];

    if (searchQuery.isNotEmpty) {
      // Score tasks
      for (final task in tasks) {
        double score = 0;
        String matchType = '';

        if (_searchByTagsOnly) {
          if (_tagsMatch(task.tags, searchQuery)) {
            score = 1.0;
            matchType = 'tag';
          }
        } else {
          // Check text match
          final textScore = _fuzzyMatchScore(task.text, searchQuery);
          if (textScore > score) {
            score = textScore;
            matchType = 'text';
          }

          // Check note match
          if (task.note != null) {
            final noteScore = _fuzzyMatchScore(task.note!, searchQuery) * 0.8;
            if (noteScore > score) {
              score = noteScore;
              matchType = 'note';
            }
          }

          // Check tag match
          if (_tagsMatch(task.tags, searchQuery)) {
            score = (score + 0.9).clamp(0.0, 1.0);
            matchType = matchType.isEmpty ? 'tag' : '$matchType+tag';
          }
        }

        if (score > 0.3) {
          scoredTasks.add((item: task, score: score, matchType: matchType));
        }
      }

      // Score notes
      for (final note in notes) {
        double score = 0;
        String matchType = '';

        if (_searchByTagsOnly) {
          if (_tagsMatch(note.tags, searchQuery)) {
            score = 1.0;
            matchType = 'tag';
          }
        } else {
          // Check title match
          if (note.optionalTitle != null) {
            final titleScore =
                _fuzzyMatchScore(note.optionalTitle!, searchQuery) * 1.1;
            if (titleScore > score) {
              score = titleScore;
              matchType = 'title';
            }
          }

          // Check content match
          final contentScore = _fuzzyMatchScore(note.content, searchQuery);
          if (contentScore > score) {
            score = contentScore;
            matchType = 'content';
          }

          // Check tag match
          if (_tagsMatch(note.tags, searchQuery)) {
            score = (score + 0.9).clamp(0.0, 1.0);
            matchType = matchType.isEmpty ? 'tag' : '$matchType+tag';
          }
        }

        if (score > 0.3) {
          scoredNotes.add((item: note, score: score, matchType: matchType));
        }
      }

      // Score journal entries
      for (final entry in journalEntries) {
        double score = 0;
        String matchType = '';

        if (_searchByTagsOnly) {
          if (_tagsMatch(entry.tags, searchQuery)) {
            score = 1.0;
            matchType = 'tag';
          }
        } else {
          // Check body match
          final bodyScore = _fuzzyMatchScore(entry.body, searchQuery);
          if (bodyScore > score) {
            score = bodyScore;
            matchType = 'body';
          }

          // Check tag match
          if (_tagsMatch(entry.tags, searchQuery)) {
            score = (score + 0.9).clamp(0.0, 1.0);
            matchType = matchType.isEmpty ? 'tag' : '$matchType+tag';
          }
        }

        if (score > 0.3) {
          scoredJournals.add((item: entry, score: score, matchType: matchType));
        }
      }

      // Sort by score
      scoredTasks.sort((a, b) => b.score.compareTo(a.score));
      scoredNotes.sort((a, b) => b.score.compareTo(a.score));
      scoredJournals.sort((a, b) => b.score.compareTo(a.score));
    }

    final totalResults =
        scoredTasks.length + scoredNotes.length + scoredJournals.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _searchByTagsOnly
                    ? 'Search by tags...'
                    : 'Search tasks, notes, journals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_searchByTagsOnly ? 'Tags Only' : 'Fuzzy Search'),
                  avatar: Icon(
                    _searchByTagsOnly ? Icons.tag : Icons.search,
                    size: 18,
                  ),
                  selected: _searchByTagsOnly,
                  onSelected: (selected) {
                    setState(() {
                      _searchByTagsOnly = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                if (searchQuery.isNotEmpty)
                  Text(
                    '$totalResults ${totalResults == 1 ? 'result' : 'results'}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search your tasks, notes, and journals',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try: project names, tags, or keywords',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : totalResults == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different keywords or toggle search mode',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      if (scoredTasks.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.task_alt, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Tasks (${scoredTasks.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...scoredTasks.map((scored) => _buildTaskTile(scored)),
                      ],
                      if (scoredNotes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.note, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Notes (${scoredNotes.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...scoredNotes.map((scored) => _buildNoteTile(scored)),
                      ],
                      if (scoredJournals.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.book, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Journal Entries (${scoredJournals.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...scoredJournals.map(
                          (scored) => _buildJournalTile(scored),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(({Task item, double score, String matchType}) scored) {
    final task = scored.item;
    return ListTile(
      leading: Icon(
        task.category == 'event' ? Icons.event : Icons.circle,
        size: task.category == 'event' ? 24 : 12,
        color: task.status == 'done'
            ? Colors.grey
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        task.text,
        style: TextStyle(
          decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
          color: task.status == 'done' ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.tags.isNotEmpty)
            Text(
              task.tags.join(' '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          if (task.note != null && task.note!.isNotEmpty)
            Text(
              task.note!,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.8),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate)} • Match: ${scored.matchType}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getScoreColor(scored.score),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${(scored.score * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(({Note item, double score, String matchType}) scored) {
    final note = scored.item;
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(note.optionalTitle ?? 'Untitled Note'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (note.tags.isNotEmpty)
            Text(
              note.tags.join(' '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          Text(
            '${DateFormat('MMM d, yyyy').format(note.creationDate)} • Match: ${scored.matchType}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getScoreColor(scored.score),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${(scored.score * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildJournalTile(
    ({JournalEntry item, double score, String matchType}) scored,
  ) {
    final entry = scored.item;
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(DateFormat('EEEE, MMMM d, yyyy').format(entry.creationDate)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (entry.tags.isNotEmpty)
            Text(
              entry.tags.join(' '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          Text(
            'Match: ${scored.matchType}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getScoreColor(scored.score),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${(scored.score * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.grey;
  }
}
