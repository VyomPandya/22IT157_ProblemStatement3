import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/providers/providers.dart';
import 'package:voice_todo_app/screens/task_edit_screen.dart';
import 'package:voice_todo_app/widgets/command_feedback.dart';
import 'package:voice_todo_app/widgets/network_status_indicator.dart';
import 'package:voice_todo_app/widgets/task_item.dart';
import 'package:voice_todo_app/widgets/voice_command_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow Voice'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: NetworkStatusIndicator(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Tasks list
          tasksAsync.when(
            data: (tasks) => _buildTasksList(context, ref, tasks),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(
                'Error loading tasks: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          
          // Command feedback
          const Positioned(
            bottom: 100,  // Above the voice button
            left: 0,
            right: 0,
            child: CommandFeedback(),
          ),
        ],
      ),
      
      // Add FAB for manual task creation
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskEditScreen.add(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
      
      // Voice command button at the bottom
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(bottom: 24),
        child: const VoiceCommandButton(),
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try saying "Add a new task"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Sort tasks: incomplete first, then by due date, then by creation date
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        // First by completion status
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        
        // Then by due date (tasks with due dates come first)
        if (a.dueDate != null && b.dueDate == null) {
          return -1;
        }
        if (a.dueDate == null && b.dueDate != null) {
          return 1;
        }
        if (a.dueDate != null && b.dueDate != null) {
          final dateCmp = a.dueDate!.compareTo(b.dueDate!);
          if (dateCmp != 0) {
            return dateCmp;
          }
        }
        
        // Finally by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return TaskItem(
          task: task,
          onToggle: () => _handleToggleTask(ref, task),
          onDelete: () => _handleDeleteTask(ref, task),
          onEdit: () => _handleEditTask(context, ref, task),
        );
      },
    );
  }

  void _handleToggleTask(WidgetRef ref, Task task) {
    final taskService = ref.read(taskServiceProvider);
    taskService.toggleTaskCompletion(task.id);
  }

  void _handleDeleteTask(WidgetRef ref, Task task) {
    final taskService = ref.read(taskServiceProvider);
    taskService.deleteTask(task.id);
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            taskService.addTask(task);
          },
        ),
      ),
    );
  }

  void _handleEditTask(BuildContext context, WidgetRef ref, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task),
      ),
    );
  }
} 