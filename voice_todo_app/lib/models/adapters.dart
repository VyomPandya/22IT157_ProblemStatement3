import 'package:hive/hive.dart';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';

// TaskAdapter
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.isSynced);
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

// CommandTypeAdapter
class CommandTypeAdapter extends TypeAdapter<CommandType> {
  @override
  final int typeId = 2;

  @override
  CommandType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CommandType.addTask;
      case 1:
        return CommandType.completeTask;
      case 2:
        return CommandType.deleteTask;
      case 3:
        return CommandType.listTasks;
      case 4:
        return CommandType.updateTask;
      default:
        return CommandType.unknown;
    }
  }

  @override
  void write(BinaryWriter writer, CommandType obj) {
    switch (obj) {
      case CommandType.addTask:
        writer.writeByte(0);
        break;
      case CommandType.completeTask:
        writer.writeByte(1);
        break;
      case CommandType.deleteTask:
        writer.writeByte(2);
        break;
      case CommandType.listTasks:
        writer.writeByte(3);
        break;
      case CommandType.updateTask:
        writer.writeByte(4);
        break;
      case CommandType.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// VoiceCommandAdapter
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
      id: fields[0] as String,
      rawText: fields[1] as String,
      type: fields[2] as CommandType,
      parameters: Map<String, dynamic>.from(fields[3] as Map),
      timestamp: fields[4] as DateTime,
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