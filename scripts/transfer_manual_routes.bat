@echo off
REM Transfer manual_routes.json to/from Android device using ADB
REM Make sure ADB is in your PATH

echo ========================================
echo Manual Routes File Transfer Tool
echo ========================================
echo.
echo 1. Push (PC to Phone)
echo 2. Pull (Phone to PC)
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo Pushing manual_routes.json to phone...
    adb push "c:\Dev\E-Map\assets\data\manual_routes.json" /sdcard/Download/manual_routes.json
    echo Done! File saved to phone's Download folder.
) else if "%choice%"=="2" (
    echo Pulling manual_routes.json from phone...
    adb pull /sdcard/Download/manual_routes.json "c:\Dev\E-Map\assets\data\manual_routes.json"
    echo Done! File updated on PC.
) else (
    echo Invalid choice.
)

pause
