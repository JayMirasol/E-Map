# Floor-Specific Manual Route System

## Overview
The manual route system now supports **floor-specific path overrides** for cross-floor navigation. This allows you to create different custom paths on each floor for the same start-destination pair (e.g., BFO→MISSO).

## How It Works

### Storage Format
Manual routes are now stored with floor-specific keys:
- **Old format**: `"BFO->MISSO"` (single route for all floors)
- **New format**: `"1:BFO->MISSO"`, `"2:BFO->MISSO"` (separate route per floor)

### Cross-Floor Navigation Example: BFO → MISSO

1. **Floor 1 Path**: 
   - Route from BFO to the stairs connector on Floor 1
   - Stored as: `"1:BFO->MISSO"`

2. **Floor 2 Path**:
   - Route from stairs connector to MISSO on Floor 2
   - Stored as: `"2:BFO->MISSO"`

3. **Automatic Switching**:
   - When navigating BFO→MISSO, starts on Floor 1 with the custom Floor 1 path
   - Automatically switches to Floor 2 and shows the custom Floor 2 path
   - Each floor uses its own manually-defined route

## Creating Floor-Specific Routes

### Step-by-Step Guide

1. **Start Route Creation**
   - Select BFO as start room
   - Select MISSO as destination room
   - Enable "Manual Route" toggle

2. **Draw Floor 1 Path**
   - Long-press on the Floor 1 map to add waypoints
   - Create path from BFO to the stairs/connector
   - The UI shows: "Editing Floor 1: X points"

3. **Switch to Floor 2**
   - Click "Switch floor" button
   - Select Floor 2
   - Edit mode continues automatically

4. **Draw Floor 2 Path**
   - Long-press on the Floor 2 map to add waypoints
   - Create path from stairs/connector to MISSO
   - The UI shows: "Editing Floor 2: X points"

5. **Save Routes**
   - Click "Save manual route" button
   - Both floor paths are saved separately
   - System creates reverse routes automatically

## UI Features

### Floor Status Display
When in edit mode, you'll see:
```
Floor Status:
[✓ F1: 8]  [✓ F2: 6]  [○ F3: 0]  [○ F4: 0]
```
- ✓ = Has points
- ○ = No points
- Blue highlight = Current floor

### Edit Mode Controls
- **Undo**: Remove last point on current floor
- **Clear floor**: Remove all points on current floor
- **Switch floor**: Navigate to another floor while keeping edit mode active
- **Save manual route**: Save all floor-specific paths

### Navigation Display
During navigation, you'll see:
- Current floor's custom path (if defined)
- "Switch floor" overlay when transitioning
- Each floor animates its own path independently

## Technical Details

### Data Structure
```dart
// Stored in LocalStore as:
{
  "1:BFO->MISSO": [
    {
      "floor": 1,
      "points": [{"fx": 0.2, "fy": 0.3}, ...]
    }
  ],
  "2:BFO->MISSO": [
    {
      "floor": 2,
      "points": [{"fx": 0.5, "fy": 0.6}, ...]
    }
  ]
}
```

### Route Resolution Priority
1. **Floor-specific manual routes** (e.g., `"1:BFO->MISSO"`)
2. **Legacy manual routes** (e.g., `"BFO->MISSO"`) - backward compatible
3. **Auto-generated pathfinding** - default fallback

### Backward Compatibility
- Old manual routes (without floor prefix) still work
- System checks new format first, then falls back to old format
- No data migration needed

## Benefits

✅ **Accurate Floor Transitions**: Define exact path on each floor  
✅ **Flexible Routing**: Different paths per floor for same destination  
✅ **Visual Feedback**: See which floors have custom paths  
✅ **Seamless Editing**: Switch floors without losing progress  
✅ **Auto-switching**: Automatic floor transitions during navigation  

## Demo Route: BFO → MISSO

This demo showcases the floor-specific routing:
1. Navigate from BFO (Ground Floor) to MISSO (2nd Floor)
2. Floor 1 shows custom path to stairs
3. Auto-switches to Floor 2
4. Floor 2 shows custom path from stairs to MISSO
5. Each floor's animation plays independently
