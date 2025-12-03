@echo off
echo ================================================
echo Pull Latest Manual Routes from Android Device
echo ================================================
echo.
echo This will pull manual_routes.json from your phone
echo and save it to your project directory.
echo.
echo Prerequisites:
echo 1. Phone connected via USB
echo 2. USB debugging enabled
echo 3. ADB installed
echo.
pause

echo.
echo Checking ADB connection...
adb devices

echo.
echo Pulling file from phone...
echo Looking in common Android app locations...

REM Try to pull from app's internal storage
adb pull /data/data/com.example.emap_mobile/app_flutter/manual_routes.json "%TEMP%\manual_routes_phone.json" 2>nul

if not exist "%TEMP%\manual_routes_phone.json" (
    echo File not found in app internal storage. Trying external storage...
    adb pull /sdcard/Android/data/com.example.emap_mobile/files/manual_routes.json "%TEMP%\manual_routes_phone.json" 2>nul
)

if not exist "%TEMP%\manual_routes_phone.json" (
    echo File not found in external storage. Trying Downloads folder...
    adb pull /sdcard/Download/manual_routes.json "%TEMP%\manual_routes_phone.json" 2>nul
)

if exist "%TEMP%\manual_routes_phone.json" (
    echo.
    echo ✓ File found on phone!
    echo.
    
    REM Get file info
    for %%A in ("%TEMP%\manual_routes_phone.json") do set size=%%~zA
    set /a sizeKB=%size%/1024
    echo   Size: %sizeKB% KB
    
    echo.
    echo Copy options:
    echo 1. Replace project file (c:\Dev\E-Map\assets\data\manual_routes.json)
    echo 2. Save to Downloads folder as backup
    echo 3. Cancel
    echo.
    set /p choice="Enter choice (1, 2, or 3): "
    
    if "%choice%"=="1" (
        copy "%TEMP%\manual_routes_phone.json" "c:\Dev\E-Map\assets\data\manual_routes.json"
        echo.
        echo ✓ Project file updated successfully!
    ) else if "%choice%"=="2" (
        copy "%TEMP%\manual_routes_phone.json" "c:\Users\Jay Mirasol\Downloads\manual_routes_from_phone.json"
        echo.
        echo ✓ Saved to Downloads folder as manual_routes_from_phone.json
    ) else (
        echo.
        echo Operation cancelled.
    )
    
    del "%TEMP%\manual_routes_phone.json"
) else (
    echo.
    echo ✗ Could not find manual_routes.json on phone.
    echo.
    echo The file might be in a different location. Try:
    echo   adb shell "find /sdcard -name manual_routes.json"
    echo.
    echo Or manually copy it using your phone's file manager
    echo to the Download folder, then pull it:
    echo   adb pull /sdcard/Download/manual_routes.json
)

echo.
pause
