import 'dart:async';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/services/database_service.dart';
import 'package:voice_todo_app/services/sync_service.dart';

class TaskService {
  final DatabaseService _databaseService;
  final SyncService _syncService;

  final _tasksController = StreamController<List<Task>>.broadcast();
  List<Task> _cachedTasks = [];

  Stream<List<Task>> get tasks => _tasksController.stream;

  TaskService(this._databaseService, this._syncService) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _cachedTasks = await _databaseService.getAllTasks();
    _tasksController.add(_cachedTasks);
  }

  Future<void> addTask(Task task) async {
    // Save to local database
    await _databaseService.saveTask(task);
    
    // Sync with Firebase if possible
    await _syncService.syncTask(task);
    
    // Update cache and notify listeners
    _cachedTasks.add(task);
    _tasksController.add(_cachedTasks);
  }

  Future<void> updateTask(Task task) async {
    // Save to local database
    await _databaseService.updateTask(task);
    
    // Sync with Firebase if possible
    await _syncService.syncTask(task);
    
    // Update cache and notify listeners
    final index = _cachedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _cachedTasks[index] = task;
      _tasksController.add(_cachedTasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Delete from local database
    await _databaseService.deleteTask(taskId);
    
    // Update cache and notify listeners
    _cachedTasks.removeWhere((task) => task.id == taskId);
    _tasksController.add(_cachedTasks);
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _cachedTasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _cachedTasks[index];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    }
  }

  Future<List<Task>> getTasks({
    bool? isCompleted,
    DateTime? dueDate,
    String? searchQuery,
  }) async {
    if (_cachedTasks.isEmpty) {
      await _loadTasks();
    }

    return _cachedTasks.where((task) {
      bool matches = true;
      
      // Filter by completion status
      if (isCompleted != null) {
        matches = matches && (task.isCompleted == isCompleted);
      }
      
      // Filter by due date
      if (dueDate != null && task.dueDate != null) {
        matches = matches && 
          (task.dueDate!.year == dueDate.year &&
           task.dueDate!.month == dueDate.month &&
           task.dueDate!.day == dueDate.day);
      }
      
      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        matches = matches && 
          (task.title.toLowerCase().contains(query) || 
           (task.description?.toLowerCase().contains(query) ?? false));
      }
      
      return matches;
    }).toList();
  }

  Future<Task?> findTaskByTitle(String title) async {
    if (_cachedTasks.isEmpty) {
      await _loadTasks();
    }

    final normalizedTitle = title.toLowerCase().trim();
    try {
      return _cachedTasks.firstWhere(
        (task) => task.title.toLowerCase().contains(normalizedTitle),
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _tasksController.close();
  }
} 