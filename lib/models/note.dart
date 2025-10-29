import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  late String content;

  @HiveField(1)
  late DateTime creationDate;

  @HiveField(2)
  String? optionalTitle;

  @HiveField(3)
  List<String> tags = [];
}
