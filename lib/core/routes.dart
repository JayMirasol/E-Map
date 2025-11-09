import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/map_2d_screen.dart';
import '../screens/map_selection_screen.dart';
import '../screens/floor_map_screen.dart';
import '../screens/rooms_screen.dart';
import '../screens/schedules_screen.dart';
import '../screens/faculty_screen.dart';
import '../screens/labs_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/about_screen.dart';
import '../screens/floorplan_screen.dart';
import '../screens/login_screen.dart';

class AppRoutes {
  static const landing = '/landing';
  static const home = '/'; // features list
  static const map = '/map';
  static const map2d = '/map2d';
  static const mapSelection = '/map-selection';
  static const floor1 = '/floor1';
  static const floor2 = '/floor2';
  static const floor3 = '/floor3';
  static const floor4 = '/floor4';
  static const rooms = '/rooms';
  static const schedules = '/schedules';
  static const faculty = '/faculty';
  static const labs = '/labs';
  static const admin = '/admin';
  static const about = '/about';
  static const floorplan = '/floorplan';
  static const login = '/login';

  static Map<String, WidgetBuilder> build() => {
    landing: (_) => const LandingScreen(),
    home: (_) => const HomeScreen(),
    map: (_) => const MapScreen(),
    map2d: (_) => const Map2DScreen(),
    mapSelection: (_) => const MapSelectionScreen(),
    floor1: (_) => const FloorMapScreen(
      floorNumber: 1,
      floorTitle: 'Ground Floor',
      imagePath: 'assets/images/1ST FLOOR.jpg',
    ),
    floor2: (_) => const FloorMapScreen(
      floorNumber: 2,
      floorTitle: '2nd Floor: Main Building',
      imagePath: 'assets/images/2ND FLOOR.jpg',
    ),
    floor3: (_) => const FloorMapScreen(
      floorNumber: 3,
      floorTitle: '3rd Floor',
      imagePath: 'assets/images/3RD FLOOR.jpg',
    ),
    floor4: (_) => const FloorMapScreen(
      floorNumber: 4,
      floorTitle: '4th Floor',
      imagePath: 'assets/images/4TH FLOOR.jpg',
    ),
    rooms: (_) => const RoomsScreen(),
    schedules: (_) => const SchedulesScreen(),
    faculty: (_) => const FacultyScreen(),
    labs: (_) => const LabsScreen(),
    admin: (_) => const AdminScreen(),
    about: (_) => const AboutScreen(),
    floorplan: (_) => const FloorplanScreen(),
    login: (_) => const LoginScreen(),
  };
}
