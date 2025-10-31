// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task()
      ..text = fields[0] as String
      ..status = fields[1] as String
      ..dueDate = fields[2] as DateTime
      ..tags = (fields[3] as List).cast<String>()
      ..category = fields[4] as String
      ..note = fields[5] as String?
      ..googleCalendarEventId = fields[6] as String?
      ..lastModified = fields[7] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.googleCalendarEventId)
      ..writeByte(7)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
