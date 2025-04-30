# Setup Guide for Voice Todo App

This guide will help you set up the Voice Todo App and fix any issues that may arise during setup.

## Quick Setup (Recommended)

For a quick setup, follow these steps:

1. **Fix Missing Font Issues**:
   - Option 1: Remove font dependencies (already done)
   - Option 2: Download Poppins fonts (see Font Issues section below)

2. **Generate Hive Models**:
   - For Windows: Run `fix_hive_models.bat`
   - For Mac/Linux: Run `./fix_hive_models.sh` (make executable first with `chmod +x fix_hive_models.sh`)
   - Or use the manual method below

3. **Run the app**:
   - `flutter run` (for mobile/desktop)
   - `flutter run -d chrome` (for web, with limitations)

## Web Platform Limitations

When running the app on the web, be aware of these limitations:

1. **Speech Recognition**: Browser security restrictions may limit speech recognition functionality.
   - You'll need to use HTTPS or localhost for speech recognition to work
   - Some browsers may prompt the user for microphone permissions
   - Recognition quality may be lower on web compared to native platforms

2. **Local Storage**: The app uses a different storage mechanism on web.
   - Data is stored in IndexedDB instead of the file system
   - Storage is limited to the browser's storage quota

3. **TTS (Text-to-Speech)**: Voice feedback will have some differences on web.
   - Web uses the browser's built-in speech synthesis
   - Voice quality and available voices differ by browser

## Detailed Setup Instructions

### Missing Hive Generated Files

The app uses Hive for local storage, which requires generated code files. If you encounter errors related to missing `.g.dart` files, follow these steps:

#### Windows Users

1. Open a command prompt in the project directory
2. Run the provided batch file:
   ```
   fix_hive_models.bat
   ```

#### Mac/Linux Users

1. Open a terminal in the project directory
2. Make the script executable and run it:
   ```
   chmod +x fix_hive_models.sh
   ./fix_hive_models.sh
   ```

#### Manual Method (All Platforms)

1. Run `flutter pub get` to update dependencies
2. Run `flutter pub run build_runner clean`
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`

### Font Issues

There are two ways to handle font issues:

#### Option 1: Use System Fonts (Already Implemented)

The app has been modified to use system fonts instead of Poppins. This is the simplest solution and requires no additional setup.

#### Option 2: Install Poppins Fonts

If you want to use the Poppins font as originally intended:

1. Create the fonts directory (if it doesn't exist):
   ```
   mkdir -p assets/fonts
   ```

2. Download the Poppins font files:
   - Visit [Google Fonts - Poppins](https://fonts.google.com/specimen/Poppins)
   - Download the font family
   - Extract and copy these specific files to the `assets/fonts/` directory:
     * Poppins-Regular.ttf
     * Poppins-Medium.ttf
     * Poppins-SemiBold.ttf
     * Poppins-Bold.ttf

3. Uncomment the font section in `pubspec.yaml`:
   - Remove the `#` characters from the font configuration

4. Uncomment the font family in `main.dart`:
   - Remove the `//` from the fontFamily line

### Other Fixed Issues

The following issues have also been fixed in the codebase:

1. **Duplicate Hive Adapters**:
   - Fixed conflict between adapters in models files and adapters.dart by using `hide` directive in imports

2. **Connectivity API Updates**:
   - Updated ConnectivityService to work with the latest version of connectivity_plus
   - The API now returns a List<ConnectivityResult> instead of a single ConnectivityResult

3. **Web Platform Support**:
   - Added conditional logic to handle web platform differently
   - Use IndexedDB for storage on web instead of file-based storage
   - Adjusted speech recognition and TTS settings for web compatibility

### Speech Recognition Issues

If you encounter issues with speech recognition:

1. Ensure you have the proper platform-specific permissions set up:
   - For Android: Check the AndroidManifest.xml file for microphone permissions
   - For iOS: Check Info.plist for microphone permissions

2. Make sure you're testing on a real device, as speech recognition often works poorly in emulators

## Troubleshooting

If you still experience issues:

1. Run `flutter clean` to clean the project
2. Delete the `.dart_tool` directory
3. Run `flutter pub get` to fetch dependencies
4. Run the Hive build steps mentioned above again 