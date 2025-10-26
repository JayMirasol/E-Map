// lib/providers/campus_provider.dart
import 'dart:convert';
import 'dart:math' as math;
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

  // Admin-controlled path overrides loaded from assets/data/path_overrides.json
  // Shape: { "4": { "L406->R405": ["L403", "R403"] } }
  final Map<int, Map<String, List<String>>> _pathOverrides = {};

  Future<void> load() async {
    // Rooms still from assets for now
    if (_rooms.isEmpty) {
      final roomsStr = await rootBundle.loadString('assets/data/rooms.json');
      _rooms = (jsonDecode(roomsStr) as List)
          .map((e) => Room.fromJson(e))
          .toList();
    }

    // Optionally load instructor photos if you store them in assets/data/instructor_photos.json
    try {
      final photosStr = await rootBundle.loadString(
        'assets/data/instructor_photos.json',
      );
      final Map<String, dynamic> pmap =
          jsonDecode(photosStr) as Map<String, dynamic>;
      pmap.forEach((k, v) {
        if (v is String && v.isNotEmpty) instructorPhotos[k] = v;
      });
      if (kDebugMode) {
        debugPrint(
          'Loaded instructor_photos.json with ${instructorPhotos.length} entries.',
        );
        instructorPhotos.forEach((k, v) => debugPrint('  photo: "$k" -> "$v"'));
      }
    } catch (_) {
      if (kDebugMode) debugPrint('No instructor_photos.json found (ok).');
    }

    // Schedules from local document storage (seeded from assets on first run)
    final rows = await LocalStore.readSchedules();
    _schedules = rows.map((e) => Schedule.fromJson(e)).toList();
    notifyListeners();
    await _loadGraphs();
    await _loadPathOverrides();
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

  Future<void> _loadPathOverrides() async {
    try {
      final txt = await rootBundle.loadString(
        'assets/data/path_overrides.json',
      );
      final raw = jsonDecode(txt) as Map<String, dynamic>;
      _pathOverrides.clear();
      raw.forEach((floorKey, value) {
        final f = int.tryParse(floorKey);
        if (f == null) return;
        final mm = <String, List<String>>{};
        if (value is Map<String, dynamic>) {
          value.forEach((pair, v) {
            if (v is List) {
              mm[pair] = v.map((e) => e.toString()).toList();
            }
          });
        }
        if (mm.isNotEmpty) _pathOverrides[f] = mm;
      });
      if (kDebugMode) {
        debugPrint(
          'Loaded path_overrides for floors: '
          '${_pathOverrides.keys.toList()}',
        );
      }
    } catch (_) {
      // optional file; ignore if missing
      if (kDebugMode) debugPrint('No path_overrides.json found (ok).');
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
  String? photoForInstructor(String instructor) {
    return instructorPhotos[instructor];
  }

  /// Returns true if instructor has a schedule AND that schedule includes current time.
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

  // ---------- Pathfinding helpers (A* over FloorGraph) ----------

  /// Find a hallway-accurate route between rooms on the same floor using the
  /// FloorGraph. Returns a polyline as fractional points: [{fx, fy}, ...].
  /// If the graph is missing or no route is found, we fall back to a simple
  /// straight line from the room centers.
  Future<List<Map<String, double>>> findPathBetweenRooms(
    String startRoomId,
    String endRoomId, {
    bool allowOverrides = true,
  }) async {
    final startRoom = roomById(startRoomId);
    final endRoom = roomById(endRoomId);
    if (startRoom == null || endRoom == null) return [];

    if (startRoom.floor == null ||
        endRoom.floor == null ||
        startRoom.floor != endRoom.floor) {
      // Different floors handled elsewhere (stairs/elevators). No single-graph route.
      return [];
    }
    final floor = startRoom.floor!;

    // Routing overrides loaded from assets (admin-controlled)
    if (allowOverrides) {
      final map = _pathOverrides[floor];
      if (map != null) {
        final key = '${startRoom.id}->${endRoom.id}';
        final list = map[key];
        if (list != null && list.isNotEmpty) {
          final ids = [startRoom.id, ...list, endRoom.id];
          final out = <Map<String, double>>[];
          for (int i = 0; i < ids.length - 1; i++) {
            final seg = await findPathBetweenRooms(
              ids[i],
              ids[i + 1],
              allowOverrides: false,
            );
            if (seg.isEmpty) continue;
            if (out.isEmpty) {
              out.addAll(seg);
            } else {
              out.addAll(seg.skip(1));
            }
          }
          if (out.isNotEmpty) return out;
        }
      }
    }

    final graph = graphForFloor(floor);

    // Fallback anchors to ensure we always return something usable
    final startPoint = {'fx': startRoom.fx ?? 0.5, 'fy': startRoom.fy ?? 0.5};
    final endPoint = {'fx': endRoom.fx ?? 0.5, 'fy': endRoom.fy ?? 0.5};

    if (graph == null || graph.nodes.isEmpty) {
      return [startPoint, endPoint];
    }

    // Build adjacency from graph edges (edges may already be bidirectional in JSON)
    final Map<String, Map<String, double>> adj = {};
    void addEdge(String from, String to, double c) {
      adj.putIfAbsent(from, () => {});
      adj[from]![to] = c;
    }

    for (final e in graph.edges) {
      // Trust cost provided; models already compute Euclidean as default
      addEdge(e.from, e.to, e.cost);
      // Ensure graph is navigable even if JSON forgot the reverse edge
      if ((adj[e.to] == null) || (adj[e.to]![e.from] == null)) {
        addEdge(e.to, e.from, e.cost);
      }
    }

    // Positions map for quick math
    final Map<String, Map<String, double>> nodesPos = {
      for (final entry in graph.nodes.entries)
        entry.key: {'fx': entry.value.fx, 'fy': entry.value.fy},
    };

    // Choose best graph-attachment nodes for both rooms:
    // 1) Use explicit door mapping by room name or id when available
    // 2) Otherwise, pick nearest graph node to the room's fx/fy
    String _nearestNodeToPoint(double fx, double fy) {
      String best = nodesPos.keys.first;
      var bestD = double.infinity;
      for (final k in nodesPos.keys) {
        final n = nodesPos[k]!;
        final dx = n['fx']! - fx;
        final dy = n['fy']! - fy;
        final d2 = dx * dx + dy * dy;
        if (d2 < bestD) {
          bestD = d2;
          best = k;
        }
      }
      return best;
    }

    String? _doorForRoom(Room r) {
      // Try exact name, then id, then some friendly fallbacks
      final byName = graph.roomToDoorNode[r.name];
      if (byName != null) return byName;
      final byId = graph.roomToDoorNode[r.id];
      if (byId != null) return byId;
      return null;
    }

    final startAttach =
        _doorForRoom(startRoom) ??
        _nearestNodeToPoint(startPoint['fx']!, startPoint['fy']!);
    final endAttach =
        _doorForRoom(endRoom) ??
        _nearestNodeToPoint(endPoint['fx']!, endPoint['fy']!);

    // A* search over the directed adjacency
    final nodeIds = nodesPos.keys.toList();
    final gScore = <String, double>{
      for (final n in nodeIds) n: double.infinity,
    };
    final fScore = <String, double>{
      for (final n in nodeIds) n: double.infinity,
    };
    final cameFrom = <String, String>{};
    final open = <String>{startAttach};

    gScore[startAttach] = 0.0;
    double _heur(String a, String b) {
      final ax = nodesPos[a]!['fx']!, ay = nodesPos[a]!['fy']!;
      final bx = nodesPos[b]!['fx']!, by = nodesPos[b]!['fy']!;
      final dx = ax - bx, dy = ay - by;
      return math.sqrt(dx * dx + dy * dy);
    }

    fScore[startAttach] = _heur(startAttach, endAttach);

    String? current;
    while (open.isNotEmpty) {
      current = open.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);
      if (current == endAttach) {
        // reconstruct
        final pathIds = <String>[];
        var c = current;
        while (true) {
          pathIds.insert(0, c);
          if (!cameFrom.containsKey(c)) break;
          c = cameFrom[c]!;
        }
        // convert to points and anchor exact room points at ends
        final pts = <Map<String, double>>[];
        // Start anchor at the real room position, then path along corridor
        pts.add({'fx': startPoint['fx']!, 'fy': startPoint['fy']!});
        for (final id in pathIds) {
          final n = nodesPos[id]!;
          pts.add({'fx': n['fx']!, 'fy': n['fy']!});
        }
        pts.add({'fx': endPoint['fx']!, 'fy': endPoint['fy']!});
        return pts;
      }
      open.remove(current);
      final neigh = adj[current] ?? const <String, double>{};
      for (final entry in neigh.entries) {
        final nb = entry.key;
        final cost = entry.value;
        final tentative = gScore[current]! + cost;
        if (tentative < (gScore[nb] ?? double.infinity)) {
          cameFrom[nb] = current;
          gScore[nb] = tentative;
          fScore[nb] = tentative + _heur(nb, endAttach);
          open.add(nb);
        }
      }
    }

    // No corridor path found; try a minimal composed path via the nearest
    // corridor attachments to avoid a misleading giant diagonal.
    final fallback = <Map<String, double>>[];
    fallback.add({'fx': startPoint['fx']!, 'fy': startPoint['fy']!});
    final sa = nodesPos[startAttach];
    if (sa != null) fallback.add({'fx': sa['fx']!, 'fy': sa['fy']!});
    final ea = nodesPos[endAttach];
    if (ea != null) fallback.add({'fx': ea['fx']!, 'fy': ea['fy']!});
    fallback.add({'fx': endPoint['fx']!, 'fy': endPoint['fy']!});
    return fallback;
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
