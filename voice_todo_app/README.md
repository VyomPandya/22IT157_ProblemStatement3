# TaskFlow Voice - Voice-Driven To-Do List App

A Flutter-based voice-driven to-do list application that allows users to manage their tasks entirely through voice commands.

## Features

- **Voice Command Interface**: Add, update, complete, and delete tasks using natural language commands
- **Offline Voice Support**: Commands are cached locally when offline and synchronized when connectivity is restored
- **Real-time Sync**: Tasks are synchronized in real-time across all devices
- **Speech Feedback**: Audible confirmations and prompts for ambiguous commands
- **Clean, Modern UI**: Intuitive interface designed for both touch and voice interaction

## Voice Commands Examples

- "Add a new task to buy groceries"
- "Add a task to call mom tomorrow"
- "Mark the groceries task as completed"
- "Delete the call mom task"
- "Show me all my tasks"
- "Show completed tasks"
- "What tasks do I have for today?"

## Technical Architecture

- **Frontend**: Flutter with Riverpod for state management
- **Voice Processing**: On-device speech recognition with cloud fallback
- **Local Storage**: Hive database for offline caching
- **Backend**: Firebase for real-time synchronization
- **Text-to-Speech**: Feedback using Flutter TTS

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Create a Firebase project
   - Update the `firebase_options.dart` file with your project credentials
4. Run `flutter run` to start the application

## Dependencies

- flutter_riverpod: State management
- speech_to_text: Voice recognition
- flutter_tts: Text-to-speech
- hive, hive_flutter: Local storage
- firebase_core, firebase_auth, cloud_firestore: Backend and sync
- connectivity_plus: Network status monitoring
