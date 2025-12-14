# Voice Navigation System Architecture

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                           │
│  ┌──────────────┐                        ┌──────────────┐       │
│  │ Map2DScreen  │                        │FloorMapScreen│       │
│  │              │                        │              │       │
│  │  [🔊] Button │                        │  [🔊] Button │       │
│  └──────┬───────┘                        └──────┬───────┘       │
└─────────┼──────────────────────────────────────┼───────────────┘
          │                                       │
          │ Uses                                  │ Uses
          │                                       │
          ▼                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   VoiceNavigationService                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • Analyzes route points (List<Offset>)                   │  │
│  │ • Calculates turn angles                                 │  │
│  │ • Generates instructions                                 │  │
│  │ • Announces via Text-to-Speech                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ Uses
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      flutter_tts Package                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Android: Uses Android TTS Engine                         │  │
│  │ iOS: Uses iOS AVSpeechSynthesizer                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Route Points → Voice Instructions

```
Route Points               Turn Analysis              Voice Output
━━━━━━━━━━━                ━━━━━━━━━━━━━━             ━━━━━━━━━━━━

Point A (100,100)
      │
      │ ─────────────────► Calculate angle           "Starting navigation"
      │                    between vectors
      │
Point B (200,100)
      │
      │ ─────────────────► Angle = -90°              "In 50 meters, turn left"
      │                    = LEFT TURN
      │
Point C (200,200)
      │
      │ ─────────────────► Angle = 0°                [No announcement]
      │                    = STRAIGHT                 (< 15° threshold)
      │
Point D (300,200)
      │
      │                                               "Arriving at destination"
      ▼
Destination
```

## Turn Detection Logic

```
              -180°
                │
    Sharp Left  │  Sharp Right
       (-135°)  │  (135°)
          ╲     │     ╱
           ╲    │    ╱
    Left    ╲   │   ╱    Right
    (-45°)   ╲  │  ╱     (45°)
              ╲ │ ╱
    Bear Left  ╲│╱  Bear Right
    (-15°)  ────┼──── (15°)
                │
           STRAIGHT
            (< 15°)
```

### Angle Thresholds:
- **-180° to -135°**: "Make a U-turn"
- **-135° to -90°**: "Turn sharp left"
- **-90° to -45°**: "Turn left"
- **-45° to -15°**: "Bear left"
- **-15° to +15°**: Continue straight (no instruction)
- **+15° to +45°**: "Bear right"
- **+45° to +90°**: "Turn right"
- **+90° to +135°**: "Turn sharp right"
- **+135° to +180°**: "Make a U-turn"

## Instruction Timeline

```
Time: 0s        5s        10s       15s       20s       25s
      │         │         │         │         │         │
      ▼         ▼         ▼         ▼         ▼         ▼
      
"Starting      "In 50m,   "Turn     "Continue  "In 100m  "Arrived at
navigation"    turn       right"    straight"  bear      destination"
               left"                           right"

      ├─────────┼─────────┼─────────┼─────────┼─────────┤
      
      Animation starts    User hears guidance    Animation ends
```

## Multi-Floor Navigation

```
Floor 2 (Destination: Room 201)
   │
   │  ◄── "Take elevator to go up to Floor 2"
   │
   │  [ELEVATOR/STAIRS]
   │
   │  ◄── "In 20 meters, turn right"
   │
   │  ◄── "Turn left"
   │
Floor 1 (Start: Room 105)
   │
   │  ◄── "Starting navigation to Room 201"
   │
   START
```

## Code Integration Points

### Map2DScreen Integration:
```
┌─────────────────────────────────────────┐
│ User taps "Show Route"                  │
│   │                                     │
│   ├─► _computeRoute()                   │
│   │     │                               │
│   │     ├─► Calculate path              │
│   │     │                               │
│   │     └─► START VOICE NAVIGATION      │ ◄── NEW!
│   │          │                          │
│   │          ├─► Announce start         │
│   │          └─► Begin instructions     │
│   │                                     │
│   ├─► Animation plays                   │
│   │                                     │
│   └─► _showDestinationReachedDialog()   │
│        │                                │
│        └─► Announce arrival             │ ◄── NEW!
└─────────────────────────────────────────┘
```

### FloorMapScreen Integration:
```
┌─────────────────────────────────────────┐
│ User selects start & destination        │
│   │                                     │
│   ├─► _findPath()                       │
│   │     │                               │
│   │     ├─► A* pathfinding              │
│   │     │                               │
│   │     └─► START VOICE NAVIGATION      │ ◄── NEW!
│   │                                     │
│   ├─► Animation on current floor        │
│   │                                     │
│   ├─► Reach stairs/elevator             │
│   │     │                               │
│   │     └─► Announce floor change       │ ◄── NEW!
│   │                                     │
│   ├─► Navigate to new floor             │
│   │                                     │
│   └─► Continue voice guidance           │ ◄── NEW!
└─────────────────────────────────────────┘
```

## Voice Control UI

```
┌─────────────────────────────────────────┐
│                 MAP SCREEN              │
│                                         │
│  ┌──────────┐                           │
│  │   [🔊]   │ ◄─── Voice Toggle Button  │
│  └──────────┘      (Top-right corner)  │
│                                         │
│  Tap to:                                │
│  • Enable/Disable voice                 │
│  • Shows snackbar confirmation          │
│  • Changes color: Blue (on) / Gray (off)│
│                                         │
│  [════════════════] ◄─── Route Path     │
│                                         │
│  [Start] ────────────► [Destination]    │
│                                         │
└─────────────────────────────────────────┘
```

## Feature Comparison

| Feature                    | Google Maps | E-Map Voice Nav |
|----------------------------|-------------|-----------------|
| Turn-by-turn instructions  | ✅          | ✅              |
| Distance announcements     | ✅          | ✅              |
| Real-time GPS tracking     | ✅          | ⚠️ (Manual)     |
| Multi-floor navigation     | ❌          | ✅              |
| Indoor navigation          | ⚠️ (Limited)| ✅              |
| Offline operation          | ⚠️ (Cached) | ✅              |
| Custom campus routes       | ❌          | ✅              |
| No API key required        | ❌          | ✅              |

## Customization Options

```dart
// Adjust voice settings:
_voiceNav.setVolume(0.8);        // 80% volume
_voiceNav.setSpeechRate(0.5);    // Slower speech
_voiceNav.setLanguage("fil-PH"); // Filipino

// Change instruction frequency:
_voiceNav.startTurnByTurnNavigation(
  route,
  destination,
  instructionInterval: Duration(seconds: 3), // Every 3 seconds
);

// Custom instructions:
_voiceNav.speak("Turn right after the library");
_voiceNav.speak("Pass by the cafeteria on your left");
```

## Testing Checklist

- [ ] Run `flutter pub get` ✓ (Already done)
- [ ] Add import statements to screens
- [ ] Add voice service fields to State classes
- [ ] Integrate voice calls in route methods
- [ ] Add voice toggle buttons to UI
- [ ] Test on real device (TTS works better than emulator)
- [ ] Test with headphones/Bluetooth
- [ ] Test with different routes
- [ ] Test multi-floor navigation
- [ ] Adjust volume/speech rate as needed

## File Structure

```
lib/
├── services/
│   ├── voice_navigation_service.dart           ✓ Created
│   ├── voice_navigation_integration_example.dart    ✓ Created
│   └── voice_navigation_floor_integration_example.dart ✓ Created
│
├── screens/
│   ├── map_2d_screen.dart          ← Needs integration
│   └── floor_map_screen.dart       ← Needs integration
│
└── main.dart                       ← No changes needed

VOICE_NAVIGATION_GUIDE.md           ✓ Created (Full documentation)
VOICE_NAVIGATION_QUICKSTART.dart    ✓ Created (Copy-paste snippets)
```

## Next Steps

1. **Copy code from VOICE_NAVIGATION_QUICKSTART.dart** into your screen files
2. **Run the app**: `flutter run`
3. **Test navigation** and listen for voice instructions
4. **Adjust settings** (volume, speed, language) as needed
5. **Calibrate distances** to match your map scale

## Support

- See `VOICE_NAVIGATION_GUIDE.md` for detailed documentation
- See `VOICE_NAVIGATION_QUICKSTART.dart` for ready-to-use code snippets
- Check `voice_navigation_integration_example.dart` for implementation patterns
