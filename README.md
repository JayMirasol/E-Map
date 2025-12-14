# EMAP Mobile - User Manual

## Welcome to E-MAP 👋

Hi! Welcome to **E-MAP** (Electronic Map), your smart campus navigation companion for City College of Angeles (CCA). This guide will help you get started with all the features, including our new **Voice Assistant** for hands-free navigation!

**E-MAP** is a 2D mobile application that helps you:
- 🗺️ Navigate the CCA campus and buildings
- 📍 Locate rooms, laboratories, and faculty offices
- 📅 View instructor schedules in real-time
- 🎤 Use voice commands for hands-free navigation
- 🚶 Get turn-by-turn walking directions

---

## Main Features

### 1. **Interactive Campus Map** 🏫
- View the entire CCA campus in a 2D site plan
- See all three main buildings: Main Building, NGO Building, and PAGCOR Building
- Tap any building to navigate inside

### 2. **Indoor Floor Navigation** 🏢
- Multi-floor support (Floors 1-4 for Main Building, Floors 5-6 for NGO, Floors 7-8 for PAGCOR)
- Pan and zoom floor plan images
- Tap rooms to see details and schedules
- Color-coded markers:
  - 🟢 **Green** - Available room
  - 🟠 **Orange** - Room currently occupied
  - 🔴 **Red** - Your selected destination
  - 🟣 **Purple** - Currently viewing room details

### 3. **Voice Assistant Navigation** 🎤 **NEW!**
Navigate hands-free using voice commands! Simply tap the microphone icon and speak your destination.

#### How to Use Voice Commands:
1. **Tap the microphone icon** 🎤 (top-right corner of any map screen)
2. **Wait for the prompt**: You'll see a red message: "🎤 Listening... Say your start and destination room"
3. **Speak clearly**: Say something like:
   - *"From Room 101 to Room 205"*
   - *"Navigate from Computer Lab to Library"*
   - *"Main Building to NGO Building"*
4. **Confirmation**: You'll see a green message showing your route is set
5. **Voice guidance begins**: The assistant will guide you with turn-by-turn instructions

#### Supported Voice Commands:
- "**from** [start] **to** [destination]" - Example: "from Room 101 to Room 205"
- "**navigate from** [start] **to** [destination]" - Example: "navigate from Computer Lab to Library"
- "[start] **to** [destination]" - Example: "Main Building to NGO Building"
- "**start at** [start] **destination** [destination]" - Example: "start at Cafeteria destination Dean's Office"

#### Voice Assistant Visual Prompts:
- 🔴 **Red Message** - "Listening... Say your start and destination"
- 🟢 **Green Message** - "Navigation set from [start] to [destination]"
- 🟠 **Orange Message** - "Oops! Your voice is unclear, please repeat"
- 🔴 **Red Message** - "Sorry, I could not understand"

#### Tips for Best Results:
- 🔇 **Quiet Environment**: Minimize background noise
- 🗣️ **Speak Clearly**: Enunciate room names and numbers
- 📛 **Use Full Names**: Say "Room 101" instead of just "101"
- 📶 **Internet Required**: Voice recognition needs internet connection
- 🎧 **Permission Required**: Grant microphone permission when prompted

### 4. **Instructor Schedules** 📅
- Search by instructor name or subject
- Filter by day of the week (Monday-Sunday)
- Filter by time window
- Tap any schedule to see the room on the map
- View full-day schedule for any room

### 5. **Room Search & Details** 🔍
- Floating search button on each floor
- Quick jump to any room
- View room schedules with day switcher
- See if a room is currently occupied

### 6. **Smart Routing** 🚶
- Automatic pathfinding between any two locations
- Cross-building navigation support
- Multi-floor route visualization
- Animated walking person showing your progress
- Turn-by-turn voice guidance

### 7. **Manual Route Editor** ✏️ (Advanced)
- Create custom routes for complex paths
- Draw routes floor-by-floor
- Save routes for future use
- Useful for accessibility or preferred paths

### 8. **Admin Features** 👨‍💼 (Authorized users only)
- Add/Edit/Delete schedules
- Manage room information
- Update instructor data
- Local data persistence

---

## Quick Video Guide for New Users 📹

> **Video Tutorial Coming Soon!**
> 
> **👉 To add your video:**  
> 1. Upload your video to YouTube or another video hosting platform
> 2. Open this file: `README.md`
> 3. Find this section: "Quick Video Guide for New Users"
> 4. Add your video embed code or link right below this text
> 
> **Example YouTube embed:**
> ```html
> <iframe width="560" height="315" 
>   src="https://www.youtube.com/embed/YOUR_VIDEO_ID" 
>   frameborder="0" allowfullscreen>
> </iframe>
> ```
> 
> **Or simply add a link:**
> ```markdown
> [Watch the E-MAP Tutorial Video](https://youtube.com/your-video-link)
> ```

<!-- 🎬 ADD YOUR VIDEO LINK OR EMBED CODE HERE 👇 -->





<!-- 🎬 VIDEO SECTION ENDS HERE 👆 -->

---

## Getting Started - Step by Step Guide

### First Time Setup

1. **Install the App**
   - Download E-MAP from your app store or install the APK
   - Open the app and tap "Start"

2. **Grant Permissions**
   - **Microphone** (for voice commands) - Tap "Allow" when prompted
   - **Location** (optional) - For better navigation experience

3. **Choose Your Navigation Method**
   
   **Option A: Manual Selection**
   - Tap "Select Start" to choose your starting location
   - Tap "Select Destination" to choose where you want to go
   - The route will appear automatically
   
   **Option B: Voice Commands** 🎤
   - Tap the microphone icon (🎤)
   - Wait for "Listening..."
   - Say: "From [your location] to [destination]"
   - Navigation starts automatically!

4. **Follow the Route**
   - Watch the blue line showing your path
   - Follow the voice instructions
   - Animated walking person shows your progress

### Navigating Between Buildings

1. Open "Navigate CCA Campus" (2D site plan)
2. Use voice: "From Main Building to NGO Building"
3. Or manually select start and destination buildings
4. Follow the outdoor path to the building entrance
5. App automatically switches to indoor floor plan

### Navigating Within a Floor

1. Select a building floor (e.g., "Main Building 1F")
2. Use voice: "From Room 101 to Room 105"
3. Or tap rooms to select start/destination
4. Follow the indoor path with voice guidance

### Finding an Instructor's Office

1. Go to "Schedules" from the home screen
2. Search for the instructor's name
3. Tap their schedule entry
4. Map opens automatically with their room highlighted
5. Tap "Navigate Here" to get directions

---

## Voice Assistant Troubleshooting

### "Sorry, speech recognition is not available on this device"
**Solution:**
- Ensure your Android version is 5.0 or higher
- Check that Google app is installed and updated
- Restart the app after granting permissions
- Rebuild the app: `flutter clean` then `flutter run`

### Voice commands not working
**Solution:**
- Check microphone permission in device settings
- Test your microphone in another app
- Ensure internet connection is stable
- Try speaking more clearly and slowly
- Use full room names (e.g., "Room 101" not "101")

### "Oops! Your voice is unclear"
**Solution:**
- Reduce background noise
- Speak closer to the microphone
- Enunciate room numbers clearly
- Try the alternative command format: "[start] to [destination]"
- Example: Instead of "navigate from computer lab to library", try "computer lab to library"

### Microphone icon stays red
**Solution:**
- Wait for the current listening session to complete
- If stuck, close and reopen the app
- Check that another app isn't using the microphone

---

## Technical Information

### Current Features (Implemented)

- ✅ Landing (Homepage) with background, logo, Start and About buttons
- ✅ About page with header, scrollbar & reading progress indicator
- ✅ Features hub (Room Locator, Schedules, Faculty Rooms, Laboratory Rooms, Admin, Floorplan)
- ✅ **Voice Assistant Navigation** 🎤 - Hands-free navigation with speech recognition
- ✅ **Visual Voice Prompts** - On-screen messages showing what the assistant is saying
- ✅ Schedules with Search & Filters (by instructor, subject, day, time window)

Room -> Map integration:
Tap a schedule or room → opens Map, centers room, and highlights it
Marker colors: red (selected), orange (occupied now), blue (available)

Room Details bottom sheet:
Tap a map pin (or long-press a room in list) → full day schedule for that room + day switcher

Floorplan overlay (multi-floor):
Tabs for 1F / 2F / 3F / 4F
Pan/zoom floor images with tappable hotspots
Per-floor search (floating search button) jumps/zooms to room and opens details
Calibration helper: long-press anywhere on a floor to get (fx, fy) fractional coordinates for hotspot mapping

Admin (local CRUD) for schedules:
Add / Edit / Delete schedules
Local persistence via JSON in app documents directory (seeded from assets on first run)

Planned / coming soon:

Firebase integration (Firestore + Auth) for real-time schedules & secure Admin.
Admin “Set fx/fy” editor to save hotspot coordinates in-app.
Import/export tools (e.g., Google Sheets/CSV).
Indoor routing / navigation overlays.
Role-based access (student vs admin).
Notifications for schedule changes (optional).

📦 Tech Stack

Flutter (Dart)
flutter_map (OpenStreetMap tiles) for the Map screen
Provider for app state
path_provider for local file persistence (schedules)
No server required for local mode

🗂 Project Structure (key folders)
lib/
  core/            # routes, theme
  models/          # Room, Schedule
  providers/       # CampusProvider (state, persistence, helpers)
  screens/         # UI pages (home, map, floorplan, schedules, about, admin, etc.)
  widgets/         # shared UI (start button, room tiles, details sheet, search)
assets/
  images/          # logo + 4 floor images
  data/            # rooms.json, schedules.json (seed)

✅ Prerequisites

Flutter (stable channel)
Install: https://docs.flutter.dev/get-started/install

Android Studio (for Android SDK + emulator)
https://developer.android.com/studio

JDK 17 (required for Gradle/AGP)

Use Android Studio’s bundled JBR (recommended)
C:\Program Files\Android\Android Studio\jbr
or any OpenJDK 17 distribution

🚀 Quick Start

1) Clone
git clone https://github.com/<your-username>/emap_mobile.git

cd emap_mobile

3) Configure Java 17 (choose one)

Option A – Project-local (easiest):
Edit android/gradle.properties and add:

org.gradle.java.home=C:\\Program Files\\Android\\Android Studio\\jbr


(or your JDK 17 path; escape backslashes)

Option B – Per terminal:

$env:JAVA_HOME="C:\Program Files\Java\jdk-17"
$env:Path="$env:JAVA_HOME\bin;$env:Path"
java -version  # should show 17.x

3) Install dependencies
   
flutter pub get

5) Add required assets

Images (put your real files here):

assets/images/cca_logo.png
assets/images/floor_1.png
assets/images/floor_2.png
assets/images/floor_3.png
assets/images/floor_4.png


Data (already included; edit as needed):

assets/data/rooms.json     # your floor-tagged rooms
assets/data/schedules.json # seed schedules; auto-copied to app's documents on first run


The app seeds schedules.json from assets/data/ to the app’s documents folder on first run and uses the file in documents thereafter.

5) Run on emulator or device
flutter doctor
flutter run

🧪 Troubleshooting

A) “Unsupported class file major version 68” / Java 24 warning
Use JDK 17. See “Configure Java 17” above (Option A recommended).

B) Gradle build path error with spaces
Move the project to a path without spaces (e.g., C:\Dev\emap_mobile).

👨‍💻 Contributing / Development

Use VS Code with Flutter & Dart extensions.

Follow the existing folder structure.

Keep assets small and optimized; prefer SVG/PNG for floor images.

---

## 📝 Additional Documentation

For more detailed guides, see:
- **[VOICE_COMMANDS_TESTING_GUIDE.md](VOICE_COMMANDS_TESTING_GUIDE.md)** - Complete testing instructions
- **[VOICE_COMMANDS_QUICK_REFERENCE.md](VOICE_COMMANDS_QUICK_REFERENCE.md)** - Quick reference card
- **[VOICE_COMMANDS_IMPLEMENTATION.md](VOICE_COMMANDS_IMPLEMENTATION.md)** - Technical details

---

**Developed by Jay Mirasol for City College of Angeles**  
**Version 2.0 - Now with Voice Assistant** 🎤
