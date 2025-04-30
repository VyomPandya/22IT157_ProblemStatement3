import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';
import 'package:voice_todo_app/services/connectivity_service.dart';
import 'package:voice_todo_app/services/database_service.dart';
import 'package:voice_todo_app/services/firebase_service.dart';

class SyncService {
  final DatabaseService _databaseService;
  final FirebaseService _firebaseService;
  final ConnectivityService _connectivityService;
  
  final _syncStatusController = StreamController<bool>.broadcast();
  StreamSubscription? _networkStatusSubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  Stream<bool> get onSyncStatusChanged => _syncStatusController.stream;
  bool get isSyncing => _isSyncing;

  SyncService(
    this._databaseService,
    this._firebaseService,
    this._connectivityService,
  ) {
    _initNetworkListener();
    _startPeriodicSync();
  }

  void _initNetworkListener() {
    _networkStatusSubscription = _connectivityService.onStatusChange.listen((status) {
      if (status == NetworkStatus.online) {
        syncAll();
      }
    });
  }

  void _startPeriodicSync() {
    // Try to sync every 2 minutes if online
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_connectivityService.currentStatus == NetworkStatus.online) {
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (kIsWeb) return; // Disable sync on web
    if (_isSyncing || _connectivityService.currentStatus == NetworkStatus.offline) {
      return;
    }

    try {
      _isSyncing = true;
      _syncStatusController.add(_isSyncing);

      // Check if user is logged in
      final isLoggedIn = await _firebaseService.isLoggedIn();
      if (!isLoggedIn) {
        await _firebaseService.signInAnonymously();
      }

      // Sync unprocessed voice commands first
      final pendingCommands = await _databaseService.getPendingCommands();
      if (pendingCommands.isNotEmpty) {
        await _firebaseService.syncCommands(pendingCommands);
        
        // Mark commands as processed
        for (final command in pendingCommands) {
          await _databaseService.markCommandAsProcessed(command.id);
        }
      }

      // Sync tasks that haven't been synced yet
      final allTasks = await _databaseService.getAllTasks();
      final unSyncedTasks = allTasks.where((task) => !task.isSynced).toList();
      
      if (unSyncedTasks.isNotEmpty) {
        await _firebaseService.syncTasks(unSyncedTasks);
        
        // Mark tasks as synced
        for (final task in unSyncedTasks) {
          final syncedTask = task.copyWith(isSynced: true);
          await _databaseService.updateTask(syncedTask);
        }
      }

      // Clean up old processed commands
      await _databaseService.clearProcessedCommands();
    } finally {
      _isSyncing = false;
      _syncStatusController.add(_isSyncing);
    }
  }

  // Sync a single task when it's modified
  Future<void> syncTask(Task task) async {
    if (kIsWeb) return; // Disable sync on web
    if (_connectivityService.currentStatus == NetworkStatus.offline) {
      // Save locally as not synced
      final unSyncedTask = task.copyWith(isSynced: false);
      await _databaseService.saveTask(unSyncedTask);
      return;
    }

    try {
      // Try to sync with Firebase
      await _firebaseService.addTask(task);
      
      // Save locally as synced
      final syncedTask = task.copyWith(isSynced: true);
      await _databaseService.saveTask(syncedTask);
    } catch (e) {
      // In case of failure, save locally as not synced
      final unSyncedTask = task.copyWith(isSynced: false);
      await _databaseService.saveTask(unSyncedTask);
    }
  }

  // Queue voice command for processing
  Future<void> queueVoiceCommand(VoiceCommand command) async {
    // Always save locally first
    await _databaseService.saveCommand(command);
    if (kIsWeb) return; // Disable sync on web
    
    // If online, try to sync immediately
    if (_connectivityService.currentStatus == NetworkStatus.online) {
      try {
        await _firebaseService.syncCommand(command);
        await _databaseService.markCommandAsProcessed(command.id);
      } catch (e) {
        // Failed to sync, it will be synced later
      }
    }
  }

  void dispose() {
    _networkStatusSubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
  }
} 