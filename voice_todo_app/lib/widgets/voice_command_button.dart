import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:voice_todo_app/providers/providers.dart';
import 'package:voice_todo_app/services/command_executor_service.dart';
import 'package:voice_todo_app/services/voice_service.dart';

class VoiceCommandButton extends ConsumerStatefulWidget {
  const VoiceCommandButton({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends ConsumerState<VoiceCommandButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _rippleTimer;
  double _rippleRadius = 0;
  bool _showRipple = false;

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
    _rippleTimer?.cancel();
    super.dispose();
  }

  void _startRippleAnimation() {
    _showRipple = true;
    _rippleRadius = 0;
    
    _rippleTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          _rippleRadius = (_rippleRadius == 0) ? 40 : 0;
        });
      }
    });
  }

  void _stopRippleAnimation() {
    _rippleTimer?.cancel();
    _rippleTimer = null;
    if (mounted) {
      setState(() {
        _showRipple = false;
      });
    }
  }

  Future<void> _handleVoiceCommand() async {
    final voiceService = ref.read(voiceServiceProvider);
    final commandExecutorService = ref.read(commandExecutorServiceProvider);
    
    if (voiceService.status == VoiceServiceStatus.idle) {
      // Start listening
      _startRippleAnimation();
      _animController.forward();
      
      await voiceService.startListening();
    } else if (voiceService.status == VoiceServiceStatus.listening) {
      // Stop listening
      _stopRippleAnimation();
      _animController.reverse();
      
      await voiceService.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceStatus = ref.watch(voiceServiceStatusProvider).valueOrNull;
    final isListening = voiceStatus == VoiceServiceStatus.listening;
    final isProcessing = voiceStatus == VoiceServiceStatus.processing;
    final lastRecognizedWords = ref.watch(lastRecognizedWordsProvider);
    
    // Update animation based on voice status
    if (isListening && !_animController.isCompleted) {
      _animController.forward();
      _startRippleAnimation();
    } else if (!isListening && _animController.isCompleted) {
      _animController.reverse();
      _stopRippleAnimation();
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recognized text display
        if (lastRecognizedWords.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              lastRecognizedWords,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
        // Voice button
        GestureDetector(
          onTap: isProcessing ? null : _handleVoiceCommand,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isListening ? 80 : 70,
            height: isListening ? 80 : 70,
            decoration: BoxDecoration(
              color: isListening ? Colors.red : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Colors.red : Theme.of(context).primaryColor).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effect when listening
                if (_showRipple)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _rippleRadius,
                    height: _rippleRadius,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                
                // Mic or Loading icon
                if (isProcessing)
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                else
                  AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _animController,
                    size: 30,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
        
        // Status text
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            isListening
                ? "Listening..."
                : isProcessing
                    ? "Processing..."
                    : "Tap to speak",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 