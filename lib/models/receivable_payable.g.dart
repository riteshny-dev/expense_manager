// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receivable_payable.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceivablePayableAdapter extends TypeAdapter<ReceivablePayable> {
  @override
  final int typeId = 1;

  @override
  ReceivablePayable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceivablePayable(
      name: fields[0] as String,
      amount: fields[1] as double,
      isReceivable: fields[2] as bool,
      fromWhom: fields[3] as String?,
      date: fields[4] as DateTime?,
      paymentMode: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReceivablePayable obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.isReceivable)
      ..writeByte(3)
      ..write(obj.fromWhom)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.paymentMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivablePayableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
