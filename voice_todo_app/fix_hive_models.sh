#!/bin/bash

# Run build_runner to generate Hive models
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

echo "Hive model files generated successfully" 