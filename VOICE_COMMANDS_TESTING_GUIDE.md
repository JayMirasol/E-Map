# Voice Command Testing Guide

## Overview
Your E-MAP app now supports **voice commands** for hands-free navigation! Users can speak their start and destination locations instead of manually selecting them.

## Features Added

### 1. Speech Recognition
- **Package**: `speech_to_text: ^7.0.0`
- **Functionality**: Converts spoken words into text
- **Supported Platforms**: Android, iOS

### 2. Voice Command Service
- **File**: `lib/services/voice_command_service.dart`
- **Features**:
  - Listens for voice input
  - Parses start and destination from spoken text
  - Fuzzy matching for room/building names
  - Error handling for unclear speech

### 3. Voice Command Integration
- **Floor Map Screen**: Microphone button for room selection
- **2D Campus Map**: Microphone button for building selection

## How to Use

### For Users

1. **Tap the Microphone Icon** 🎤
   - Located in the top-right corner of the screen
   - Icon turns RED when listening

2. **Speak Your Command**
   - Wait for "Listening. Please say your start and destination room."
   - Speak clearly: "From [start] to [destination]"
   - Examples:
     - "From Room 101 to Room 205"
     - "Navigate from Computer Lab to Library"
     - "Main Building to NGO Building"
     - "Start at Cafeteria, destination Dean's Office"

3. **Wait for Confirmation**
   - Voice assistant confirms: "Navigation set from [start] to [destination]"
   - Route automatically displays and voice guidance begins
   - If unclear: "Oops! Your voice is unclear. Please repeat..."

### Supported Command Formats

The system understands multiple ways of saying the same thing:

#### Format 1: "from X to Y"
```
"from Room 101 to Room 205"
"navigate from Computer Lab to Library"
```

#### Format 2: "X to Y"
```
"Room 101 to Room 205"
"Main Building to NGO Building"
```

#### Format 3: "start X destination Y"
```
"start at Room 101 destination Room 205"
"start Computer Lab end at Library"
```

## Testing Steps

### Prerequisites

#### Android Testing
1. **Microphone Permissions**
   - Edit `android/app/src/main/AndroidManifest.xml`
   - Add these permissions INSIDE the `<manifest>` tag:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.BLUETOOTH"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   ```

2. **Internet Connection**
   - Speech recognition may use cloud services
   - Ensure device has internet access

#### iOS Testing (Future)
1. Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for voice navigation commands</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>This app needs speech recognition for voice navigation</string>
   ```

### Installation & Setup

1. **Install Dependencies**
   ```bash
   cd C:\Dev\E-Map
   flutter pub get
   ```

2. **Verify Installation**
   ```bash
   flutter pub deps | Select-String "speech_to_text"
   ```
   Should show: `speech_to_text 7.0.0`

3. **Build & Run**
   ```bash
   flutter run
   ```

### Test Cases

#### Test 1: Basic Voice Command (Floor Map)
1. Open any floor map (e.g., Main Building 1F)
2. Tap microphone icon 🎤
3. Wait for "Listening..."
4. Say: "From Room 101 to Room 105"
5. **Expected Result**:
   - ✅ Voice confirms: "Navigation set from Room 101 to Room 105"
   - ✅ Route displays on map
   - ✅ Voice guidance begins

#### Test 2: Campus Navigation (2D Map)
1. Open "Navigate CCA Campus"
2. Tap microphone icon 🎤
3. Say: "From Main Building to NGO Building"
4. **Expected Result**:
   - ✅ Route shows on campus map
   - ✅ Voice announces navigation start

#### Test 3: Unclear Speech
1. Tap microphone icon 🎤
2. Mumble or say nonsense: "blah blah mumble"
3. **Expected Result**:
   - ✅ Voice says: "Oops! Your voice is unclear. Please repeat..."

#### Test 4: Partial Match
1. Tap microphone icon 🎤
2. Say: "From Computer to Library" (without "Lab" or "Room")
3. **Expected Result**:
   - ✅ System finds "Computer Lab" and "Library"
   - ✅ Navigation starts successfully

#### Test 5: Listening Indicator
1. Tap microphone icon 🎤
2. **Expected Result**:
   - ✅ Icon turns RED while listening
   - ✅ Icon returns to normal when done

### Debugging

#### Check Debug Logs

Run the app and watch for these log messages:

```
🎤 Initializing speech recognition...
✅ Speech recognition initialized successfully
🎤 Starting to listen...
🎤 Recognized: from room 101 to room 205 (final: true)
🔍 Parsing command: "from room 101 to room 205"
🔍 Pattern "from-to": start="room 101" -> "Room 101", dest="room 205" -> "Room 205"
```

#### Common Issues

**Issue: "Speech recognition not available"**
- **Cause**: Device doesn't support speech recognition
- **Solution**: Test on a different device or Android emulator with Google Play

**Issue: Microphone button doesn't respond**
- **Cause**: Missing permissions
- **Solution**: Check AndroidManifest.xml has RECORD_AUDIO permission
- **Solution**: Grant microphone permission in device settings

**Issue: "Your voice is unclear" always appears**
- **Cause**: Noisy environment or poor microphone
- **Solution**: Test in quiet room
- **Solution**: Speak closer to microphone
- **Solution**: Speak more slowly and clearly

**Issue: Wrong rooms selected**
- **Cause**: Similar room names (e.g., "Room 101" vs "Room 102")
- **Solution**: Speak full room name clearly
- **Solution**: Improve fuzzy matching algorithm (edit `voice_command_service.dart`)

## Voice Command Workflow

```
User taps microphone 🎤
    ↓
Voice assistant: "Listening. Please say your start and destination room."
    ↓
User speaks: "From Room 101 to Room 205"
    ↓
Speech-to-text converts to: "from room 101 to room 205"
    ↓
Parser extracts: start="Room 101", dest="Room 205"
    ↓
Fuzzy matcher finds closest room names
    ↓
Routes computed and displayed
    ↓
Voice assistant: "Navigation set from Room 101 to Room 205. Starting navigation."
    ↓
Turn-by-turn guidance begins
```

## Customization

### Adjust Listening Timeout

Edit `lib/services/voice_command_service.dart`:

```dart
await _voiceCommand.listenForCommand(
  timeout: const Duration(seconds: 15), // Change from 10 to 15 seconds
  // ...
);
```

### Improve Fuzzy Matching

Edit the `_findBestMatch()` method in `voice_command_service.dart` to improve room name recognition.

### Custom Error Messages

Edit `_handleVoiceCommand()` in both screen files to customize voice responses.

## Performance Tips

1. **Quiet Environment**: Test in a quiet room for best results
2. **Clear Speech**: Speak slowly and clearly
3. **Full Names**: Use complete room/building names
4. **Internet**: Ensure stable internet connection

## Success Criteria

✅ Microphone icon changes to RED when listening  
✅ Voice confirms what it heard  
✅ Route displays automatically  
✅ Error messages for unclear speech  
✅ Works on both floor maps and campus map  
✅ Fuzzy matching handles variations in speech  

## Next Steps

After testing, you can:
1. Add more sophisticated NLP (Natural Language Processing)
2. Support multiple languages
3. Add voice commands for other features (zoom, rotate, etc.)
4. Implement offline speech recognition
5. Add voice shortcuts (e.g., "take me to the cafeteria")

## Troubleshooting Commands

```bash
# Check if package installed
flutter pub deps | Select-String "speech_to_text"

# Rebuild app
flutter clean
flutter pub get
flutter run

# Check Android permissions
adb shell pm list permissions -d -g

# Check microphone access
adb shell dumpsys media.audio_flinger
```

## Contact & Support

If voice commands aren't working:
1. Check debug logs for error messages
2. Verify microphone permissions
3. Test on physical device (not emulator)
4. Ensure internet connection
5. Try restarting the app

---

**Happy Testing!** 🎤🗺️
