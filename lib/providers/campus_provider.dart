import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../models/floor_graph.dart';
import '../services/local_store.dart';

class CampusProvider with ChangeNotifier {
  List<Room> _rooms = [];
  List<Schedule> _schedules = [];

  String? _selectedRoomId;

  // NEW: map of instructor -> photo URL (populated from assets or remote source)
  final Map<String, String> instructorPhotos = {};

  List<Room> get rooms => _rooms;
  List<Schedule> get schedules => _schedules;
  String? get selectedRoomId => _selectedRoomId;

  static const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final Map<int, FloorGraph> _floorGraphs = {};
  FloorGraph? graphForFloor(int floor) => _floorGraphs[floor];

  Future<void> load() async {
    // Rooms still from assets for now
    if (_rooms.isEmpty) {
      final roomsStr = await rootBundle.loadString('assets/data/rooms.json');
      _rooms = (jsonDecode(roomsStr) as List)
          .map((e) => Room.fromJson(e))
          .toList();
    }

    // Optionally load instructor photos if you store them in assets/data/instructor_photos.json
    // Example JSON shape: { "John Doe": "https://...", "Jane Smith": "assets/images/jane.jpg" }
    try {
      final photosStr = await rootBundle.loadString(
        'assets/data/instructor_photos.json',
      );
      final Map<String, dynamic> pmap =
          jsonDecode(photosStr) as Map<String, dynamic>;
      pmap.forEach((k, v) {
        if (v is String && v.isNotEmpty) instructorPhotos[k] = v;
      });
    } catch (_) {
      // file missing is ok — thumbnails will fall back to initials
    }

    // Schedules from local document storage (seeded from assets on first run)
    final rows = await LocalStore.readSchedules();
    _schedules = rows.map((e) => Schedule.fromJson(e)).toList();
    notifyListeners();
    await _loadGraphs();
  }

  Future<void> _loadGraphs() async {
    for (final f in [1, 2, 3, 4]) {
      final path = 'assets/data/graph_floor_$f.json';
      try {
        final txt = await rootBundle.loadString(path);
        final j = jsonDecode(txt) as Map<String, dynamic>;
        _floorGraphs[f] = FloorGraph.fromJson(j);
      } catch (_) {
        // If file missing, skip; auto-routing just won’t be available for that floor
      }
    }
  }

  void selectRoom(String? id) {
    _selectedRoomId = id;
    notifyListeners();
  }

  Room? roomById(String id) {
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Room> byType(String type) =>
      _rooms.where((r) => r.type == type).toList();

  bool isRoomOccupiedNow(String roomId) {
    final now = DateTime.now();
    final weekday = todayAbbrev();
    for (final s in _schedules) {
      if (s.roomId != roomId) continue;
      if (s.day.toLowerCase().startsWith(weekday.toLowerCase())) {
        if (!now.isBefore(s.start) && !now.isAfter(s.end)) return true;
      }
    }
    return false;
  }

  String todayAbbrev() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  List<Schedule> schedulesForRoomAndDay(String roomId, String dayAbbrev) {
    final list = _schedules
        .where(
          (s) =>
              s.roomId == roomId &&
              s.day.toLowerCase().startsWith(dayAbbrev.toLowerCase()),
        )
        .toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  // --------------- NEW: instructor helpers ----------------

  /// Returns photo URL for instructor or null.
  /// Look up in `instructorPhotos` map. You can populate instructorPhotos from
  /// assets, remote API, or during admin edits.
  String? photoForInstructor(String instructor) {
    return instructorPhotos[instructor];
  }

  /// Returns true if instructor has a schedule AND that schedule includes current time
  /// (also checks the weekday abbreviation so "available now" is accurate).
  bool instructorAvailableNow(String instructor) {
    final now = DateTime.now();
    final weekday = todayAbbrev();
    for (final s in _schedules) {
      if (s.instructor != instructor) continue;
      if (!s.day.toLowerCase().startsWith(weekday.toLowerCase())) continue;
      if (!now.isBefore(s.start) && !now.isAfter(s.end)) return true;
    }
    return false;
  }

  /// Return schedules for given instructor (optionally filter by day)
  List<Schedule> schedulesForInstructor(
    String instructor, {
    String? dayAbbrev,
  }) {
    var out = _schedules.where((s) => s.instructor == instructor);
    if (dayAbbrev != null && dayAbbrev.isNotEmpty) {
      out = out.where(
        (s) => s.day.toLowerCase().startsWith(dayAbbrev.toLowerCase()),
      );
    }
    final list = out.toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  /// Return a thumbnail URL for a room (if your Room model includes thumbnailUrl)
  /// Returns null if not available.
  String? roomThumbnail(String roomId) {
    final r = roomById(roomId);
    if (r == null) return null;
    try {
      // if your Room model has thumbnailUrl field, use it
      return r.thumbnailUrl;
    } catch (_) {
      return null;
    }
  }

  // --------- CRUD for schedules ---------
  Future<void> _persist() async {
    await LocalStore.writeSchedules(_schedules.map((e) => e.toJson()).toList());
  }

  Future<void> addSchedule(Schedule s) async {
    _schedules.add(s);
    await _persist();
    notifyListeners();
  }

  Future<void> updateSchedule(Schedule s) async {
    final idx = _schedules.indexWhere((x) => x.id == s.id);
    if (idx >= 0) {
      _schedules[idx] = s;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((x) => x.id == id);
    await _persist();
    notifyListeners();
  }
}
