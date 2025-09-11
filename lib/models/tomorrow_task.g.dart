// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tomorrow_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TomorrowTaskAdapter extends TypeAdapter<TomorrowTask> {
  @override
  final int typeId = 3;

  @override
  TomorrowTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TomorrowTask(
      title: fields[0] as String,
      description: fields[1] as String,
      isDone: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TomorrowTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.isDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TomorrowTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
