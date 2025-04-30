import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_todo_app/providers/providers.dart';
import 'package:voice_todo_app/services/command_executor_service.dart';
import 'package:voice_todo_app/services/voice_service.dart';

class CommandFeedback extends ConsumerStatefulWidget {
  const CommandFeedback({Key? key}) : super(key: key);

  @override
  ConsumerState<CommandFeedback> createState() => _CommandFeedbackState();
}

class _CommandFeedbackState extends ConsumerState<CommandFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _dismissTimer;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commandResult = ref.watch(commandResultProvider);
    
    // No command result, don't show anything
    if (commandResult == null) {
      return const SizedBox.shrink();
    }
    
    // Start animation if we have a command result
    _animController.forward();
    
    // Auto-dismiss after 5 seconds
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _animController.reverse().then((_) {
          ref.read(commandResultProvider.notifier).state = null;
        });
      }
    });
    
    // Read the message right away
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakFeedback(commandResult.message);
    });
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _animController.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: commandResult.success ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: commandResult.success ? Colors.green.shade200 : Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: commandResult.success
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 28,
                        )
                      : Icon(
                          Icons.error,
                          color: Colors.red.shade600,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        commandResult.success ? 'Success' : 'Sorry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: commandResult.success
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        commandResult.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                  onPressed: () {
                    _animController.reverse().then((_) {
                      ref.read(commandResultProvider.notifier).state = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _speakFeedback(String message) async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.speak(message);
  }
} 