import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/services/command_executor_service.dart';
import 'package:voice_todo_app/services/command_parser_service.dart';
import 'package:voice_todo_app/services/connectivity_service.dart';
import 'package:voice_todo_app/services/database_service.dart';
import 'package:voice_todo_app/services/firebase_service.dart';
import 'package:voice_todo_app/services/sync_service.dart';
import 'package:voice_todo_app/services/task_service.dart';
import 'package:voice_todo_app/services/voice_service.dart';

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Command parser service provider
final commandParserServiceProvider = Provider<CommandParserService>((ref) {
  return CommandParserService();
});

// Connectivity service provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Firebase service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final service = FirebaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Voice service provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final commandParserService = ref.watch(commandParserServiceProvider);
  final service = VoiceService(commandParserService);
  ref.onDispose(() => service.dispose());
  return service;
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  final service = SyncService(databaseService, firebaseService, connectivityService);
  ref.onDispose(() => service.dispose());
  return service;
});

// Task service provider
final taskServiceProvider = Provider<TaskService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  
  final service = TaskService(databaseService, syncService);
  ref.onDispose(() => service.dispose());
  return service;
});

// Command executor service provider
final commandExecutorServiceProvider = Provider<CommandExecutorService>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  
  return CommandExecutorService(taskService, voiceService);
});

// Tasks stream provider
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.tasks;
});

// Network status provider
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.onStatusChange;
});

// Is syncing provider
final isSyncingProvider = StreamProvider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.onSyncStatusChanged;
});

// Voice service status provider
final voiceServiceStatusProvider = StreamProvider<VoiceServiceStatus>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.onStatusChanged;
});

// Last recognized words provider
final lastRecognizedWordsProvider = StateProvider<String>((ref) => "");

// Command result provider
final commandResultProvider = StateProvider<CommandResult?>((ref) => null); 