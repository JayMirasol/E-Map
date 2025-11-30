# NGO Building & PAGCOR Building Setup Guide

## Overview
Two new buildings have been added to the E-Map system:
- **NGO Building** (Floors 5-6)
- **PAGCOR Building** (Floors 7-10)

These buildings have the same features as the Main Building (Floors 1-4):
- Manual route creation
- Start/destination selection
- Room navigation
- Cross-floor/cross-building navigation
- Animated pathfinding with walking stick figure
- Legend and room details

## Floor Mapping
| Floor Number | Building | Description |
|-------------|----------|-------------|
| 1-4 | Main Building | Existing floors |
| 5 | NGO Building | Ground Floor |
| 6 | NGO Building | 2nd Floor |
| 7 | PAGCOR Building | 1st Floor |
| 8 | PAGCOR Building | 2nd Floor |
| 9 | PAGCOR Building | 3rd Floor |
| 10 | PAGCOR Building | 4th Floor |

## Files Created/Modified

### New Files Created:
1. **Graph Files** (for pathfinding):
   - `assets/data/graph_floor_5.json` - NGO Ground Floor
   - `assets/data/graph_floor_6.json` - NGO 2nd Floor
   - `assets/data/graph_floor_7.json` - PAGCOR 1st Floor
   - `assets/data/graph_floor_8.json` - PAGCOR 2nd Floor
   - `assets/data/graph_floor_9.json` - PAGCOR 3rd Floor
   - `assets/data/graph_floor_10.json` - PAGCOR 4th Floor

### Modified Files:
1. **lib/core/routes.dart** - Added 6 new routes
2. **lib/screens/map_selection_screen.dart** - Added building cards
3. **lib/screens/floor_map_screen.dart** - Updated floor navigation
4. **lib/screens/schedules_screen.dart** - Added building labels
5. **assets/data/rooms.json** - Added placeholder rooms

## Setup Instructions

### Step 1: Add Room Pinpoints
For each new building floor, you need to:

1. Open the floor map (e.g., NGO Building - Ground Floor)
2. Long-press on the map to get coordinates (fx, fy values)
3. Update `assets/data/rooms.json` with actual room locations

**Example for NGO Building rooms:**
```json
{
  "id": "NGO_CANTEEN",
  "name": "NGO Canteen",
  "type": "office",
  "floor": 5,
  "fx": 0.25,  // Update with actual coordinates
  "fy": 0.35,  // Update with actual coordinates
  "lat": 15.14715,
  "lng": 120.58745
}
```

### Step 2: Create Waypoint Network
Update the graph files (e.g., `graph_floor_5.json`) with:

1. **Corridor waypoints** - For pathfinding through hallways
2. **Room door anchors** - Connection points to rooms
3. **Stair connectors** - For cross-floor navigation

**Example graph structure:**
```json
{
  "metadata": {
    "floor": 5,
    "building": "NGO",
    "title": "NGO Building - Ground Floor Graph"
  },
  "nodes": {
    "NGO_CORRIDOR_1": {
      "x": 300,
      "y": 500,
      "fx": 0.3,
      "fy": 0.5,
      "type": "corridor"
    },
    "NGO_STAIRS_GF": {
      "x": 500,
      "y": 800,
      "fx": 0.5,
      "fy": 0.8,
      "type": "stair",
      "connects_to_floor": 6
    }
  },
  "edges": {
    "NGO_CORRIDOR_1": {
      "NGO_STAIRS_GF": {"cost": 10}
    }
  }
}
```

### Step 3: Create Manual Routes
1. Select start and destination rooms in different buildings
2. The app will prompt you to create manual routes
3. Long-press to add waypoints along the path
4. Routes are saved automatically

### Step 4: Test Cross-Building Navigation
Test navigation between:
- Main Building ↔ NGO Building
- Main Building ↔ PAGCOR Building
- NGO Building ↔ PAGCOR Building

## Placeholder Rooms Added

### NGO Building (Floor 5 - Ground):
- NGO_CANTEEN
- N101, N102, N103

### NGO Building (Floor 6 - 2nd):
- NGO_IEAS
- N203, N204, N205

### PAGCOR Building (Floors 7-10):
- Floor 7: P101-P105
- Floor 8: P201-P205
- Floor 9: P301-P305
- Floor 10: P401-P405

**Note:** All placeholder rooms have generic coordinates (fx: 0.3-0.7, fy: 0.3-0.7). Update these with actual positions by long-pressing on the map.

## Image Locations

### NGO Building Images:
- Ground Floor: `assets/images/NGO BUILDING/GROUNDFLOOR/NGO GROUND FLOOR.jpg`
- 2nd Floor: `assets/images/NGO BUILDING/SECOND FLOOR/NGO 2ND FLOOR.jpg`

### PAGCOR Building Images:
- 1st Floor: `assets/images/PAGCOR BUILDING/BLDG 2 1ST FLOOR F.jpg`
- 2nd Floor: `assets/images/PAGCOR BUILDING/BLDG 2 2ND FLOOR.jpg`
- 3rd Floor: `assets/images/PAGCOR BUILDING/BLDG 2 3RD FLOOR F.jpg`
- 4th Floor: `assets/images/PAGCOR BUILDING/BLDG 2 4TH FLOOR F.jpg`

## Features Available

All existing features work on the new buildings:
✅ Manual route creation
✅ Start/destination selection
✅ Room search functionality
✅ Room details view
✅ Legend display
✅ Animated pathfinding
✅ Walking stick figure animation
✅ Cross-floor navigation dialogs
✅ "See Direction First" option
✅ Looping animations

## Navigation Flow

1. User selects a room in NGO Building as start
2. User selects a room in Main Building as destination
3. App detects cross-building navigation
4. User creates manual route by long-pressing waypoints
5. Route is saved and can be reused
6. Animated navigation shows path across floors/buildings

## Tips for Setup

1. **Start with main corridors**: Create corridor waypoints first
2. **Connect stairs**: Ensure stair nodes connect floors properly
3. **Test incrementally**: Test navigation floor-by-floor
4. **Use consistent naming**: Follow naming conventions (NGO_, P_)
5. **Document special rooms**: Mark important rooms (offices, labs, etc.)

## Troubleshooting

### Issue: Can't see new buildings in map selection
- **Solution**: Restart the app, check routes.dart is updated

### Issue: Rooms don't appear on map
- **Solution**: Verify rooms.json has correct floor numbers (5-10)

### Issue: Cross-building navigation doesn't work
- **Solution**: Create manual routes connecting the buildings

### Issue: Images not loading
- **Solution**: Check image paths match exactly (case-sensitive)

## Next Steps

1. Map all actual rooms with correct coordinates
2. Create waypoint networks for each floor
3. Set up stair connectors between floors
4. Create manual routes between buildings
5. Add room schedules if applicable
6. Test all navigation paths

## Support

For questions or issues, refer to:
- FLOOR_SPECIFIC_ROUTES.md - Manual route creation guide
- WAYPOINTS_GUIDE.md - Waypoint system documentation
- README.md - General E-Map documentation
