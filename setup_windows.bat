@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ==============================================
echo    Flutter TODO Manager - First-time setup
 echo ==============================================
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter not found in PATH.
  echo Install Flutter SDK and add flutter\bin to PATH.
  echo https://docs.flutter.dev/get-started/install
  pause
  exit /b 1
)
echo [1/3] Generating Android and Web platform files...
call flutter create --platforms=android,web .
if errorlevel 1 goto :failed
echo [2/3] Installing packages...
call flutter pub get
if errorlevel 1 goto :failed
echo [3/3] Checking Flutter installation...
call flutter doctor
echo.
echo Setup finished. Open this folder in VS Code.
echo To run on Android: flutter run
 echo To run in Chrome: flutter run -d chrome
pause
exit /b 0
:failed
echo Setup failed. Check the error above.
pause
exit /b 1
