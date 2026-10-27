@echo off
echo ========================================================
echo MeetMind AI (2027) — Building Production Android APK
echo ========================================================
echo Checking Flutter SDK...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK is not in your Windows PATH.
    echo Please install Flutter from https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [1/3] Getting Flutter packages...
call flutter pub get

echo [2/3] Building Release APK...
call flutter build apk --release

echo [3/3] Building Android App Bundle (for Google Play Store)...
call flutter build appbundle --release

echo.
echo ========================================================
echo Build Complete!
echo APK Output: build\app\outputs\flutter-apk\app-release.apk
echo AAB Output: build\app\outputs\bundle\release\app-release.aab
echo ========================================================
pause
