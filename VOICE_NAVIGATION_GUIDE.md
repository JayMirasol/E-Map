# Voice Navigation Feature - Implementation Guide

## Overview
This guide explains how to add **voice-guided turn-by-turn navigation** to the E-Map app, similar to Google Maps. Users will hear instructions like "turn left", "turn right", "continue straight", etc., as they navigate the campus.

## What's Been Added

### 1. Voice Navigation Service (`lib/services/voice_navigation_service.dart`)
A comprehensive service that provides:
- **Turn-by-turn voice instructions** (turn left, turn right, continue straight, etc.)
- **Automatic direction calculation** from route points
- **Distance announcements** ("in 50 meters, turn right")
- **Floor change announcements** ("take the stairs to go up to floor 2")
- **Start/arrival announcements**
- **Volume and speech rate controls**
- **Enable/disable toggle**

### 2. Key Features
- ✅ Real-time voice guidance based on route geometry
- ✅ Intelligent turn detection (sharp turns, gentle curves, U-turns)
- ✅ Customizable instruction intervals (default: every 5 seconds)
- ✅ Multi-floor support with floor transition announcements
- ✅ Works offline (no internet required after TTS engine is downloaded)
- ✅ Cross-platform (iOS & Android)

## Installation Steps

### Step 1: Install Dependencies
Run this command in your terminal:
```bash
flutter pub get
```

This will install the `flutter_tts: ^4.0.2` package that was added to pubspec.yaml.

### Step 2: Platform-Specific Setup

#### Android
No additional setup required! Text-to-speech works out of the box.

#### iOS (if building for iOS)
Add to `ios/Podfile`:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

## Integration Guide

### For 2D Campus Map (`map_2d_screen.dart`)

1. **Import the service**:
```dart
import '../services/voice_navigation_service.dart';
```

2. **Add to your State class**:
```dart
class _Map2DScreenState extends State<Map2DScreen> with TickerProviderStateMixin {
  // ... existing fields ...
  
  final VoiceNavigationService _voiceNav = VoiceNavigationService();
  bool _voiceEnabled = true;
```

3. **Dispose properly**:
```dart
@override
void dispose() {
  _voiceNav.dispose();
  // ... rest of dispose code ...
  super.dispose();
}
```

4. **Start voice navigation when route is shown**:
```dart
void _computeRoute() {
  // ... your existing route computation ...
  
  setState(() {
    _currentRoute = computedRoute;
    _pathAnimationController.forward(from: 0.0);
  });
  
  // NEW: Start voice guidance
  if (_voiceEnabled && _currentRoute != null && _destinationLocationId != null) {
    final destination = _getLocationById(_destinationLocationId!);
    _voiceNav.announceNavigationStart(destination.name);
    
    _voiceNav.startTurnByTurnNavigation(
      _currentRoute!,
      destination.name,
      instructionInterval: const Duration(seconds: 5),
    );
  }
}
```

5. **Add voice control button** in your build() method:
```dart
Positioned(
  top: 16,
  right: 16,
  child: FloatingActionButton(
    mini: true,
    heroTag: 'voice_campus',
    backgroundColor: _voiceEnabled ? Colors.blue : Colors.grey,
    tooltip: _voiceEnabled ? 'Disable voice' : 'Enable voice',
    onPressed: () {
      setState(() {
        _voiceEnabled = !_voiceEnabled;
        _voiceNav.setEnabled(_voiceEnabled);
      });
    },
    child: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
  ),
)
```

### For Floor Maps (`floor_map_screen.dart`)

1. **Import and add service** (same as above)

2. **Announce floor changes**:
```dart
void _switchToFloor(int newFloor, String connector) {
  // Announce before switching
  if (_voiceEnabled) {
    _voiceNav.announceFloorChange(
      widget.floorNumber,
      newFloor,
      connector, // e.g., "Stairs A" or "Elevator B"
    );
  }
  
  // ... navigate to new floor ...
}
```

3. **Continue guidance on new floor**:
```dart
void _continueRouteOnFloor() {
  if (_voiceEnabled && _currentFloorRoute != null) {
    _voiceNav.speak("Continue following the path");
    
    // Optionally restart turn-by-turn for this floor segment
    _voiceNav.startTurnByTurnNavigation(
      _currentFloorRoute!,
      _destinationRoomName,
    );
  }
}
```

## Usage Examples

### Basic Voice Announcement
```dart
_voiceNav.speak("Welcome to E-Map navigation");
```

### Announce Navigation Start
```dart
_voiceNav.announceNavigationStart("Room 301");
```

### Turn-by-Turn Navigation
```dart
final route = [
  Offset(100, 100),
  Offset(200, 100),
  Offset(200, 200),
  Offset(300, 250),
];

_voiceNav.startTurnByTurnNavigation(
  route,
  "Main Building",
  instructionInterval: Duration(seconds: 5),
);
```

### Announce Arrival
```dart
_voiceNav.announceArrival("Room 301");
```

### Announce Floor Change
```dart
_voiceNav.announceFloorChange(1, 2, "Stairs A");
// Speaks: "Take the stairs to go up to floor 2"
```

### Control Voice Settings
```dart
// Enable/disable
_voiceNav.setEnabled(false);

// Adjust volume (0.0 to 1.0)
_voiceNav.setVolume(0.8);

// Adjust speech rate (0.0 to 1.0)
_voiceNav.setSpeechRate(0.5); // slower = clearer
```

## How It Works

### Direction Detection Algorithm
The service analyzes route points to detect turns:
1. Takes 3 consecutive points (previous, current, next)
2. Calculates the angle between vectors
3. Determines direction based on angle:
   - **> 135°**: U-turn
   - **90° - 135°**: Sharp turn
   - **45° - 90°**: Regular turn
   - **15° - 45°**: Bear left/right
   - **< 15°**: Continue straight

### Distance Estimation
Currently uses pixel distances. To calibrate for real-world meters:
```dart
// In voice_navigation_service.dart, update _formatDistance()
String _formatDistance(double distance) {
  // Calibrate: measure real distance in meters for a known pixel distance
  const pixelsPerMeter = 10.0; // Example: adjust based on your map scale
  final meters = distance / pixelsPerMeter;
  
  if (meters < 10) return "a short distance";
  if (meters < 50) return "${(meters / 10).round() * 10} meters";
  if (meters < 100) return "about ${(meters / 10).round() * 10} meters";
  return "about ${(meters / 50).round() * 50} meters";
}
```

## Testing

1. **Run the app**: `flutter run`
2. **Navigate to a location**: Use "Navigate CCA Campus" feature
3. **Select start and destination**: Choose two buildings/rooms
4. **Listen**: You should hear:
   - "Starting navigation to [destination]"
   - Turn-by-turn instructions every 5 seconds
   - "You have arrived at [destination]" when complete

## Customization

### Change Voice Language
```dart
await _flutterTts.setLanguage("en-GB"); // British English
await _flutterTts.setLanguage("fil-PH"); // Filipino (if available)
```

### Adjust Instruction Frequency
```dart
// More frequent updates (every 3 seconds)
_voiceNav.startTurnByTurnNavigation(
  route,
  destination,
  instructionInterval: Duration(seconds: 3),
);
```

### Custom Instructions
```dart
// Add your own landmarks or campus-specific instructions
_voiceNav.speak("Pass by the library, then turn right at the cafeteria");
```

## Troubleshooting

### No Voice Output
- **Check volume**: Ensure device volume is up
- **Test TTS**: Call `_voiceNav.speak("test")` directly
- **Check enabled state**: Verify `_voiceEnabled == true`

### Voice Too Fast/Slow
```dart
_voiceNav.setSpeechRate(0.3); // Slower (0.0 - 1.0)
_voiceNav.setSpeechRate(0.7); // Faster
```

### Wrong Directions
- **Calibrate distance thresholds** in `_getDirectionInstruction()`
- **Adjust turn angle sensitivity** (currently 15° minimum)
- **Check route point density** (more points = better accuracy)

### Instructions Too Frequent/Sparse
- Adjust `instructionInterval` parameter
- Modify `_generateInstructions()` to filter insignificant turns

## Future Enhancements

- [ ] GPS integration for outdoor real-time position tracking
- [ ] Landmark-based instructions ("Turn left at the library")
- [ ] Multilingual support (Filipino, etc.)
- [ ] Speed-based instruction timing
- [ ] Custom voice profiles
- [ ] Accessibility features (haptic feedback)

## API Reference

See complete documentation in `voice_navigation_service.dart`.

Key methods:
- `speak(String)` - Speak any text
- `announceNavigationStart(String)` - Start announcement
- `startTurnByTurnNavigation(List<Offset>, String, {Duration})` - Main navigation
- `announceArrival(String)` - Arrival announcement
- `announceFloorChange(int, int, String)` - Floor transition
- `setEnabled(bool)` - Enable/disable voice
- `setVolume(double)` - Adjust volume
- `setSpeechRate(double)` - Adjust speed
- `stop()` - Stop speaking
- `dispose()` - Clean up

## Summary

✅ **Yes, voice navigation is absolutely possible!**
✅ Works offline after initial TTS engine download
✅ No API keys or internet required
✅ Cross-platform (Android & iOS)
✅ Fully customizable instructions
✅ Easy to integrate into existing screens

The implementation uses the `flutter_tts` package which leverages the native TTS engines on Android and iOS, providing high-quality, natural-sounding voice guidance similar to Google Maps.
