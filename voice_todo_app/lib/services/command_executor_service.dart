import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';
import 'package:voice_todo_app/services/task_service.dart';
import 'package:voice_todo_app/services/voice_service.dart';

class CommandResult {
  final bool success;
  final String message;
  final dynamic data;

  CommandResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class CommandExecutorService {
  final TaskService _taskService;
  final VoiceService _voiceService;

  CommandExecutorService(this._taskService, this._voiceService);

  Future<CommandResult> executeCommand(VoiceCommand command) async {
    switch (command.type) {
      case CommandType.addTask:
        return _executeAddTask(command);
      case CommandType.completeTask:
        return _executeCompleteTask(command);
      case CommandType.deleteTask:
        return _executeDeleteTask(command);
      case CommandType.listTasks:
        return _executeListTasks(command);
      case CommandType.updateTask:
        return _executeUpdateTask(command);
      case CommandType.unknown:
      default:
        return CommandResult(
          success: false,
          message: "I couldn't understand that command. Please try again.",
        );
    }
  }

  Future<CommandResult> _executeAddTask(VoiceCommand command) async {
    final title = command.parameters['title'] as String?;
    final dueDate = command.parameters['dueDate'] as DateTime?;

    if (title == null || title.isEmpty) {
      return CommandResult(
        success: false,
        message: "I couldn't understand the task title. Please try again with a clear task name.",
      );
    }

    final task = Task(
      title: title,
      dueDate: dueDate,
    );

    await _taskService.addTask(task);

    final confirmationMessage = dueDate != null
        ? "Added task '$title' due on ${_formatDate(dueDate)}."
        : "Added task '$title'.";

    return CommandResult(
      success: true,
      message: confirmationMessage,
      data: task,
    );
  }

  Future<CommandResult> _executeCompleteTask(VoiceCommand command) async {
    final taskIdentifier = command.parameters['taskIdentifier'] as String?;

    if (taskIdentifier == null || taskIdentifier.isEmpty) {
      return CommandResult(
        success: false,
        message: "I couldn't identify which task to mark as complete. Please try again with the task name.",
      );
    }

    // Try to find the task by name or part of the name
    final task = await _taskService.findTaskByTitle(taskIdentifier);

    if (task == null) {
      return CommandResult(
        success: false,
        message: "I couldn't find a task named '$taskIdentifier'. Please try again with a different task name.",
      );
    }

    if (task.isCompleted) {
      return CommandResult(
        success: true,
        message: "Task '${task.title}' is already completed.",
        data: task,
      );
    }

    await _taskService.toggleTaskCompletion(task.id);

    return CommandResult(
      success: true,
      message: "Marked task '${task.title}' as completed.",
      data: task,
    );
  }

  Future<CommandResult> _executeDeleteTask(VoiceCommand command) async {
    final taskIdentifier = command.parameters['taskIdentifier'] as String?;

    if (taskIdentifier == null || taskIdentifier.isEmpty) {
      return CommandResult(
        success: false,
        message: "I couldn't identify which task to delete. Please try again with the task name.",
      );
    }

    // Try to find the task by name or part of the name
    final task = await _taskService.findTaskByTitle(taskIdentifier);

    if (task == null) {
      return CommandResult(
        success: false,
        message: "I couldn't find a task named '$taskIdentifier'. Please try again with a different task name.",
      );
    }

    await _taskService.deleteTask(task.id);

    return CommandResult(
      success: true,
      message: "Deleted task '${task.title}'.",
    );
  }

  Future<CommandResult> _executeListTasks(VoiceCommand command) async {
    bool? isCompleted;
    DateTime? dueDate;

    // Extract status filter
    final status = command.parameters['status'] as String?;
    if (status == 'completed') {
      isCompleted = true;
    } else if (status == 'pending') {
      isCompleted = false;
    }

    // Extract date filter
    final dateFilter = command.parameters['dateFilter'] as Map<String, dynamic>?;
    if (dateFilter != null) {
      final filterType = dateFilter['type'] as String?;
      
      if (filterType != null) {
        dueDate = _parseDateFilter(filterType);
      }
    }

    // Get filtered tasks
    final tasks = await _taskService.getTasks(
      isCompleted: isCompleted,
      dueDate: dueDate,
    );

    if (tasks.isEmpty) {
      String message = "You don't have any";
      if (status != null) {
        message += " $status";
      }
      message += " tasks";
      if (dueDate != null) {
        message += " for ${_formatDate(dueDate)}";
      }
      message += ".";

      return CommandResult(
        success: true,
        message: message,
        data: tasks,
      );
    }

    // Prepare the message
    String statusMessage = '';
    if (status == 'completed') {
      statusMessage = 'completed';
    } else if (status == 'pending') {
      statusMessage = 'pending';
    }

    String dateMessage = '';
    if (dueDate != null) {
      dateMessage = ' for ${_formatDate(dueDate)}';
    }

    String taskCountMessage = "You have ${tasks.length} ${statusMessage.isNotEmpty ? statusMessage + ' ' : ''}tasks${dateMessage}.";
    String taskListMessage = "Here they are: ${tasks.take(5).map((t) => t.title).join(', ')}";
    
    if (tasks.length > 5) {
      taskListMessage += ", and ${tasks.length - 5} more.";
    } else {
      taskListMessage += ".";
    }

    return CommandResult(
      success: true,
      message: "$taskCountMessage $taskListMessage",
      data: tasks,
    );
  }

  Future<CommandResult> _executeUpdateTask(VoiceCommand command) async {
    final taskIdentifier = command.parameters['taskIdentifier'] as String?;
    final newTitle = command.parameters['newTitle'] as String?;
    final dueDate = command.parameters['dueDate'] as DateTime?;

    if (taskIdentifier == null || taskIdentifier.isEmpty) {
      return CommandResult(
        success: false,
        message: "I couldn't identify which task to update. Please try again with the task name.",
      );
    }

    // Try to find the task by name or part of the name
    final task = await _taskService.findTaskByTitle(taskIdentifier);

    if (task == null) {
      return CommandResult(
        success: false,
        message: "I couldn't find a task named '$taskIdentifier'. Please try again with a different task name.",
      );
    }

    // Make sure we're actually changing something
    if (newTitle == null && dueDate == null) {
      return CommandResult(
        success: false,
        message: "I couldn't understand what to update for task '${task.title}'. Please specify a new title or due date.",
      );
    }

    // Create updated task
    final updatedTask = task.copyWith(
      title: newTitle ?? task.title,
      dueDate: dueDate ?? task.dueDate,
    );

    await _taskService.updateTask(updatedTask);

    // Prepare confirmation message
    String confirmationMessage = "Updated task";
    
    if (newTitle != null) {
      confirmationMessage += " from '${task.title}' to '${updatedTask.title}'";
    } else {
      confirmationMessage += " '${task.title}'";
    }
    
    if (dueDate != null) {
      confirmationMessage += " with due date ${_formatDate(dueDate)}";
    }
    
    confirmationMessage += ".";

    return CommandResult(
      success: true,
      message: confirmationMessage,
      data: updatedTask,
    );
  }

  DateTime? _parseDateFilter(String filterType) {
    final now = DateTime.now();
    
    switch (filterType) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'tomorrow':
        return DateTime(now.year, now.month, now.day + 1);
      case 'this_week':
        // Start of the current week (Monday)
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 1);
      case 'next_week':
        // Start of next week (next Monday)
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 8);
      default:
        return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'tomorrow';
    } else {
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
} 