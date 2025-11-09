# Waypoint System Guide

## Overview
The waypoint system allows you to create realistic navigation paths that follow hallways and corridors instead of straight lines between rooms.

## How It Works

### 1. **Waypoints are Invisible to Users**
- Users only see and select actual rooms (classrooms, labs, offices)
- Waypoints guide the path behind the scenes
- No waypoint markers appear on the map

### 2. **Adding Waypoints to rooms.json**

Add waypoint entries with these properties:

```json
{
  "id": "waypoint_4f_hall1",
  "name": "Hallway Junction 1",
  "type": "waypoint",
  "floor": 4,
  "lat": 15.14715,
  "lng": 120.58745,
  "fx": 0.500,
  "fy": 0.615,
  "waypoints": ["L401", "L402", "waypoint_4f_hall2", "R401"]
}
```

**Key Properties:**
- `type`: Must be `"waypoint"` to hide from users
- `fx`, `fy`: Position on the floor map (0.0 to 1.0)
- `waypoints`: Array of room/waypoint IDs this connects to

### 3. **Connecting Rooms to Waypoints**

Each room should list the waypoints it connects to:

```json
{
  "id": "L401",
  "name": "L401",
  "type": "classroom",
  "floor": 4,
  "fx": 0.182,
  "fy": 0.615,
  "waypoints": ["waypoint_4f_hall1"]
}
```

### 4. **Example Network Setup**

Here's how to set up a hallway with rooms on both sides:

```
L401 ←→ [waypoint_4f_hall1] ←→ R401
L402 ←→ [waypoint_4f_hall1] ←→ [waypoint_4f_hall2]
                                      ↓
L403 ←→ [waypoint_4f_hall2] ←→ R402
L404 ←→ [waypoint_4f_hall2] ←→ R403
```

**Waypoint 1:**
- Position: Middle of hallway near L401/L402
- Connects to: L401, L402, R401, waypoint_4f_hall2

**Waypoint 2:**
- Position: Middle of hallway near L403/L404
- Connects to: waypoint_4f_hall1, L403, L404, R402, R403

## Path Finding Algorithm

The system uses **Breadth-First Search (BFS)** to find the shortest path through waypoints:

1. User selects Start Room (e.g., L401)
2. User selects Destination Room (e.g., R403)
3. System finds path: L401 → waypoint_4f_hall1 → waypoint_4f_hall2 → R403
4. Line animates through each waypoint in order

## Best Practices

### ✅ DO:
- Place waypoints at hallway intersections
- Connect rooms to their nearest hallway waypoint
- Use descriptive names for waypoints (e.g., "4F_Main_Hall_Center")
- Test paths between distant rooms

### ❌ DON'T:
- Don't make waypoints selectable (always use `type: "waypoint"`)
- Don't forget to set `fx` and `fy` coordinates
- Don't create disconnected waypoint networks
- Don't place waypoints inside rooms

## Setting Up Coordinates

### For Waypoints:
1. Long-press on the floor map at hallway positions
2. Note the `fx` and `fy` values from the popup
3. Add those coordinates to your waypoint in rooms.json

### Example Workflow:
1. Long-press at hallway junction → See: `fx=0.500, fy=0.615`
2. Add to rooms.json:
   ```json
   {
     "id": "waypoint_4f_junction",
     "type": "waypoint",
     "fx": 0.500,
     "fy": 0.615,
     ...
   }
   ```

## Visual Path Rendering

The path line will:
- Start at the Start Room (green marker)
- Draw through each waypoint sequentially
- End at the Destination Room (red marker)
- Color transitions from green → red along the path
- Animate with a smooth drawing effect

## Testing Your Waypoint Setup

1. Hot reload the app (press `r` in terminal)
2. Navigate to a floor with waypoints
3. Select Start Room on one side
4. Select Destination Room on other side
5. Verify path follows hallways correctly

If the path is a straight line, check:
- Are waypoints added to rooms.json?
- Do rooms have `waypoints` arrays?
- Are waypoints properly connected to each other?

## Example: Complete 4th Floor Setup

```json
// Rooms with waypoint connections
{"id":"L401", "waypoints":["waypoint_4f_hall1"]},
{"id":"L402", "waypoints":["waypoint_4f_hall1"]},
{"id":"R401", "waypoints":["waypoint_4f_hall1"]},

// Waypoints forming hallway network
{
  "id":"waypoint_4f_hall1",
  "type":"waypoint",
  "waypoints":["L401","L402","R401","waypoint_4f_hall2"]
},
{
  "id":"waypoint_4f_hall2",
  "type":"waypoint",
  "waypoints":["waypoint_4f_hall1","L403","R402"]
}
```

This creates a network where L401 can reach R402 via two waypoints!
