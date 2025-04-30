import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voice_todo_app/models/task.dart';
import 'package:voice_todo_app/models/voice_command.dart';

class FirebaseService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  User? _currentUser;
  
  final _syncController = StreamController<bool>.broadcast();
  Stream<bool> get onSyncStatusChanged => _syncController.stream;

  FirebaseService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _syncController.add(user != null);
    });
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      _currentUser = userCredential.user;
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  String? get userId => _currentUser?.uid;

  // Task methods
  Stream<List<Task>> tasksStream() {
    if (_currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromJson(data);
      }).toList();
    });
  }

  Future<void> addTask(Task task) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('tasks')
        .doc(task.id)
        .update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Voice command syncing
  Future<void> syncCommand(VoiceCommand command) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('commands')
        .doc(command.id)
        .set(command.toJson());
  }

  // Batch operations for efficient syncing
  Future<void> syncTasks(List<Task> tasks) async {
    if (_currentUser == null || tasks.isEmpty) return;

    final batch = _firestore.batch();
    final tasksRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('tasks');

    for (final task in tasks) {
      batch.set(tasksRef.doc(task.id), task.toJson());
    }

    await batch.commit();
  }

  Future<void> syncCommands(List<VoiceCommand> commands) async {
    if (_currentUser == null || commands.isEmpty) return;

    final batch = _firestore.batch();
    final commandsRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('commands');

    for (final command in commands) {
      batch.set(commandsRef.doc(command.id), command.toJson());
    }

    await batch.commit();
  }

  void dispose() {
    _syncController.close();
  }
}
