// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 2;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry()
      ..body = fields[0] as String
      ..creationDate = fields[1] as DateTime
      ..imagePaths = (fields[2] as List).cast<String>()
      ..tags = (fields[3] as List).cast<String>()
      ..lastModified = fields[4] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.body)
      ..writeByte(1)
      ..write(obj.creationDate)
      ..writeByte(2)
      ..write(obj.imagePaths)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
