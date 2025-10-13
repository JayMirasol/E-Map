import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
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
