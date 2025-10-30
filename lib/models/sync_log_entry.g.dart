// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncLogEntryAdapter extends TypeAdapter<SyncLogEntry> {
  @override
  final int typeId = 4;

  @override
  SyncLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLogEntry(
      timestamp: fields[0] as DateTime,
      type: fields[1] as String,
      success: fields[2] as bool,
      errorMessage: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncLogEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.success)
      ..writeByte(3)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
