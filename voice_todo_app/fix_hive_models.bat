@echo off
echo Generating Hive model files...

call flutter pub get
call flutter pub run build_runner clean
call flutter pub run build_runner build --delete-conflicting-outputs

echo Hive model files generated successfully
pause 