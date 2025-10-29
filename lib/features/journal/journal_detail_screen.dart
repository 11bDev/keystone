import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:keystone/models/journal_entry.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('d MMM yyyy, hh:mm a').format(entry.creationDate),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(data: entry.body),
      ),
    );
  }
}
