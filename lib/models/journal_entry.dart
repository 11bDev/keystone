import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String body;

  @HiveField(1)
  late DateTime creationDate;

  @HiveField(2)
  List<String> imagePaths = [];

  @HiveField(3)
  List<String> tags = [];
}
