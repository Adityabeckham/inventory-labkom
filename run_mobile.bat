@echo off
echo ===================================================
echo   Inventory Labkom — Flutter Mobile Application
echo ===================================================
cd /d %~dp0mobile
flutter pub get
flutter run
pause
