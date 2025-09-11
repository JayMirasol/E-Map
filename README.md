EMAP Mobile

Hi, I'm Jay Mirasol. So this is the documentation on how to run this mobile app.

EMAP (eMap) is a 2D mobile application for location mapping and scheduling of ICSLIS instructors at City College of Angeles. This repository contains the Flutter mobile app.

✨ Description

Current features (implemented):

Landing (Homepage) with background, logo, Start and About buttons.
About page with header (logo + headings), scrollbar & reading progress indicator.
Features hub (Room Locator, Schedules, Faculty Rooms, Laboratory Rooms, Admin, Floorplan).
Schedules with Search & Filters:
Search by instructor or subject
Filter by day (Sun–Sat)
Filter by time window (start–end)

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
