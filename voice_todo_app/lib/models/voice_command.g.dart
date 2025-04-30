// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_command.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceCommandAdapter extends TypeAdapter<VoiceCommand> {
  @override
  final int typeId = 1;

  @override
  VoiceCommand read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceCommand(
      id: fields[0] as String?,
      rawText: fields[1] as String,
      type: fields[2] as CommandType,
      parameters: (fields[3] as Map).cast<String, dynamic>(),
      timestamp: fields[4] as DateTime?,
      isProcessed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceCommand obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rawText)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.parameters)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.isProcessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceCommandAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
