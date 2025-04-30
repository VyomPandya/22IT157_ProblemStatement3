import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:voice_todo_app/models/voice_command.dart';
import 'package:voice_todo_app/services/command_parser_service.dart';

enum VoiceServiceStatus {
  idle,
  listening,
  processing,
  speaking,
  error
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final CommandParserService _commandParserService;
  
  bool _isInitialized = false;
  VoiceServiceStatus _status = VoiceServiceStatus.idle;
  String _lastError = '';
  String _lastRecognizedWords = '';
  
  final _statusController = StreamController<VoiceServiceStatus>.broadcast();
  final _resultController = StreamController<VoiceCommand>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<VoiceServiceStatus> get onStatusChanged => _statusController.stream;
  Stream<VoiceCommand> get onCommandRecognized => _resultController.stream;
  Stream<String> get onError => _errorController.stream;

  VoiceServiceStatus get status => _status;
  String get lastRecognizedWords => _lastRecognizedWords;
  String get lastError => _lastError;

  VoiceService(this._commandParserService);

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize speech to text
      bool speechAvailable = await _speechToText.initialize(
        onError: (error) => _handleError('Speech recognition error: $error'),
        onStatus: (status) {
          if (status == 'done' && _status == VoiceServiceStatus.listening) {
            _setStatus(VoiceServiceStatus.processing);
          }
        },
      );

      // Initialize text to speech
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _flutterTts.setCompletionHandler(() {
        if (_status == VoiceServiceStatus.speaking) {
          _setStatus(VoiceServiceStatus.idle);
        }
      });

      _isInitialized = speechAvailable;
      return speechAvailable;
    } catch (e) {
      _handleError('Failed to initialize voice service: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        _handleError('Voice service is not initialized');
        return;
      }
    }

    if (_status == VoiceServiceStatus.listening) return;

    try {
      _setStatus(VoiceServiceStatus.listening);
      
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
      );
    } catch (e) {
      _handleError('Failed to start listening: $e');
      _setStatus(VoiceServiceStatus.idle);
    }
  }

  Future<void> stopListening() async {
    if (_status != VoiceServiceStatus.listening) return;
    
    try {
      await _speechToText.stop();
      _setStatus(VoiceServiceStatus.processing);
    } catch (e) {
      _handleError('Failed to stop listening: $e');
      _setStatus(VoiceServiceStatus.idle);
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        _handleError('Voice service is not initialized');
        return;
      }
    }

    if (_status == VoiceServiceStatus.speaking) {
      await _flutterTts.stop();
    }

    _setStatus(VoiceServiceStatus.speaking);
    await _flutterTts.speak(text);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastRecognizedWords = result.recognizedWords;
    
    if (result.finalResult) {
      _setStatus(VoiceServiceStatus.processing);
      _processRecognizedSpeech(result.recognizedWords);
    }
  }

  Future<void> _processRecognizedSpeech(String text) async {
    try {
      final command = await _commandParserService.parseCommand(text);
      _resultController.add(command);
      _setStatus(VoiceServiceStatus.idle);
    } catch (e) {
      _handleError('Failed to process speech: $e');
      _setStatus(VoiceServiceStatus.idle);
    }
  }

  void _setStatus(VoiceServiceStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void _handleError(String error) {
    _lastError = error;
    _errorController.add(error);
    _setStatus(VoiceServiceStatus.error);
    debugPrint(error);
  }

  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _statusController.close();
    _resultController.close();
    _errorController.close();
  }
} 