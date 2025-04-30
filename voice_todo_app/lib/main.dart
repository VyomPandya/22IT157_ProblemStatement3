import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_todo_app/firebase_options.dart';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';
import 'package:voice_todo_app/screens/home_screen.dart';
import 'package:voice_todo_app/services/database_service.dart';
import 'package:voice_todo_app/services/voice_service.dart';
import 'package:voice_todo_app/widgets/command_feedback.dart';
import 'package:voice_todo_app/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and local database
  try {
    await DatabaseService.initialize();
  } catch (e) {
    debugPrint('Error initializing database: $e');
    // Continue but show a message to the user later if needed
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue with app even if Firebase fails
  }
  
  runApp(
    const ProviderScope(
      child: VoiceTodoApp(),
    ),
  );
}

class VoiceTodoApp extends ConsumerStatefulWidget {
  const VoiceTodoApp({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceTodoApp> createState() => _VoiceTodoAppState();
}

class _VoiceTodoAppState extends ConsumerState<VoiceTodoApp> {
  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Initialize voice service
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.initialize();
      
      // Setup voice command listener
      voiceService.onCommandRecognized.listen((command) async {
        // Queue the command locally
        final syncService = ref.read(syncServiceProvider);
        await syncService.queueVoiceCommand(command);
        
        // Execute the command
        final commandExecutor = ref.read(commandExecutorServiceProvider);
        final result = await commandExecutor.executeCommand(command);
        
        // Update UI with command result
        ref.read(commandResultProvider.notifier).state = result;
        
        // Update last recognized words
        ref.read(lastRecognizedWordsProvider.notifier).state = command.rawText;
      });
      
      // Initial sync if online
      final syncService = ref.read(syncServiceProvider);
      syncService.syncAll();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow Voice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Use system fonts instead of Poppins
        // fontFamily: 'Poppins',
        // textTheme: Typography.material2021().black.apply(fontFamily: 'Poppins'),
      ),
      home: const HomeScreen(),
    );
  }
}
