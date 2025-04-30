import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';

class DatabaseService {
  static const String _tasksBoxName = 'tasks';
  static const String _commandsBoxName = 'voice_commands';
  static late Box<Task> _tasksBox;
  static late Box<VoiceCommand> _commandsBox;

  static Future<void> initialize() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    final dbPath = path.join(appDocumentDir.path, 'hive_db');
    
    Hive.init(dbPath);
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(VoiceCommandAdapter());
    Hive.registerAdapter(CommandTypeAdapter());
    
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _commandsBox = await Hive.openBox<VoiceCommand>(_commandsBoxName);
  }

  // Task methods
  Future<List<Task>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  Future<Task?> getTask(String id) async {
    return _tasksBox.values.firstWhere(
      (task) => task.id == id,
      orElse: () => null as Task,
    );
  }

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Future<void> updateTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  // Voice command methods
  Future<List<VoiceCommand>> getPendingCommands() async {
    return _commandsBox.values
        .where((command) => !command.isProcessed)
        .toList();
  }

  Future<void> saveCommand(VoiceCommand command) async {
    await _commandsBox.put(command.id, command);
  }

  Future<void> markCommandAsProcessed(String id) async {
    final command = _commandsBox.values.firstWhere(
      (cmd) => cmd.id == id,
      orElse: () => null as VoiceCommand,
    );
    
    if (command != null) {
      command.isProcessed = true;
      await _commandsBox.put(id, command);
    }
  }

  Future<void> clearProcessedCommands() async {
    final processedCommandIds = _commandsBox.values
        .where((command) => command.isProcessed)
        .map((command) => command.id)
        .toList();
    
    for (final id in processedCommandIds) {
      await _commandsBox.delete(id);
    }
  }
} 