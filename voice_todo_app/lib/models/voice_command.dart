import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'voice_command.g.dart';

enum CommandType {
  addTask,
  completeTask,
  deleteTask,
  listTasks,
  updateTask,
  unknown
}

@HiveType(typeId: 1)
class VoiceCommand {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rawText;

  @HiveField(2)
  final CommandType type;

  @HiveField(3)
  final Map<String, dynamic> parameters;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  bool isProcessed;

  VoiceCommand({
    String? id,
    required this.rawText,
    required this.type,
    required this.parameters,
    DateTime? timestamp,
    this.isProcessed = false,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      id: json['id'],
      rawText: json['rawText'],
      type: CommandType.values.firstWhere(
        (e) => e.toString() == 'CommandType.${json['type']}',
        orElse: () => CommandType.unknown,
      ),
      parameters: json['parameters'] ?? {},
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
      isProcessed: json['isProcessed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawText': rawText,
      'type': type.toString().split('.').last,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'isProcessed': isProcessed,
    };
  }
} 