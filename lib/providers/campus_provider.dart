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

  /// Find path between two rooms on the same floor, return list of fractional points
  /// [{ 'fx': double, 'fy': double }, ...]. If graph missing or path fails, returns
  /// start->end straight line (fallback).
  Future<List<Map<String, double>>> findPathBetweenRooms(
    String startRoomId,
    String endRoomId,
  ) async {
    final startRoom = roomById(startRoomId);
    final endRoom = roomById(endRoomId);
    if (startRoom == null || endRoom == null) return [];

    if (startRoom.floor == null ||
        endRoom.floor == null ||
        startRoom.floor != endRoom.floor) {
      // different floors: no single-floor path (return empty or handle elevator stairs elsewhere)
      return [];
    }
    final floor = startRoom.floor!;
    final graph = graphForFloor(floor);
    final startPoint = {'fx': startRoom.fx ?? 0.5, 'fy': startRoom.fy ?? 0.5};
    final endPoint = {'fx': endRoom.fx ?? 0.5, 'fy': endRoom.fy ?? 0.5};

    if (graph == null) {
      // fallback straight line
      return [startPoint, endPoint];
    }

    // Try to parse nodes from graph (for common shapes)
    Map<String, Map<String, double>> nodesPos = {};
    final Map<String, Map<String, double>> neighbors = {};

    try {
      // Use graph.nodes directly (avoid dead null-aware fallback)
      final rawNodes = (graph.nodes) as Iterable<dynamic>? ?? [];
      for (final rn in rawNodes) {
        if (rn is Map) {
          final id = rn['id']?.toString();
          double? fx = (rn['fx'] ?? rn['x'] ?? rn['px']) is num
              ? (rn['fx'] ?? rn['x'] ?? rn['px']).toDouble()
              : null;
          double? fy = (rn['fy'] ?? rn['y'] ?? rn['py']) is num
              ? (rn['fy'] ?? rn['y'] ?? rn['py']).toDouble()
              : null;

          if (fx != null && fy != null && id != null && id.isNotEmpty) {
            nodesPos[id] = {'fx': fx, 'fy': fy};
          }

          // neighbors parsing
          final rawNeigh =
              (rn['neighbors'] ?? rn['edges'] ?? rn['adj'])
                  as Iterable<dynamic>? ??
              [];
          final mapNeigh = <String, double>{};
          for (final e in rawNeigh) {
            if (e is Map) {
              final to = e['to']?.toString() ?? e['id']?.toString();
              double cost = 1.0;
              if (e['cost'] is num) cost = (e['cost'] as num).toDouble();
              if (to != null) mapNeigh[to] = cost;
            } else if (e is List && e.isNotEmpty) {
              final to = e[0]?.toString();
              final cost = (e.length > 1 && e[1] is num)
                  ? (e[1] as num).toDouble()
                  : 1.0;
              if (to != null) mapNeigh[to] = cost;
            }
          }
          if (id != null && mapNeigh.isNotEmpty) neighbors[id] = mapNeigh;
        }
      }
    } catch (_) {
      // permissive: continue to fallback
    }

    // If we couldn't parse nodes (empty), fallback:
    if (nodesPos.isEmpty) {
      return [startPoint, endPoint];
    }

    // If neighbors empty, auto-connect via k-nearest approach
    Map<String, Map<String, double>> adj = {};
    if (neighbors.isNotEmpty) {
      adj = neighbors;
    } else {
      // build k-nearest adjacency (k=6)
      final ids = nodesPos.keys.toList();
      for (final id in ids) {
        final p = nodesPos[id]!;
        final dists = <String, double>{};
        for (final other in ids) {
          if (other == id) continue;
          final q = nodesPos[other]!;
          final dx = p['fx']! - q['fx']!;
          final dy = p['fy']! - q['fy']!;
          final dist = math.sqrt(dx * dx + dy * dy);
          dists[other] = dist;
        }
        final sorted = dists.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final k = math.min(6, sorted.length);
        final neigh = <String, double>{};
        for (int i = 0; i < k; i++) neigh[sorted[i].key] = sorted[i].value;
        adj[id] = neigh;
      }
    }

    // helper: nearest node id to a fractional point
    String nearestNode(
      Map<String, Map<String, double>> nodes,
      Map<String, double> pt,
    ) {
      String best = nodes.keys.first;
      double bestD = double.infinity;
      for (final k in nodes.keys) {
        final n = nodes[k]!;
        final dx = n['fx']! - pt['fx']!;
        final dy = n['fy']! - pt['fy']!;
        final d = dx * dx + dy * dy;
        if (d < bestD) {
          bestD = d;
          best = k;
        }
      }
      return best;
    }

    final startNode = nearestNode(nodesPos, startPoint);
    final endNode = nearestNode(nodesPos, endPoint);

    // A* implementation
    List<String> reconstructPath(Map<String, String> cameFrom, String current) {
      final path = <String>[];
      var c = current;
      while (c.isNotEmpty) {
        path.insert(0, c);
        if (!cameFrom.containsKey(c)) break;
        c = cameFrom[c]!;
      }
      return path;
    }

    final nodeIds = nodesPos.keys.toList();
    final gScore = <String, double>{
      for (final n in nodeIds) n: double.infinity,
    };
    final fScore = <String, double>{
      for (final n in nodeIds) n: double.infinity,
    };
    final cameFrom = <String, String>{};
    final open = <String>{startNode};

    gScore[startNode] = 0.0;
    final hx = nodesPos[startNode]!['fx']! - nodesPos[endNode]!['fx']!;
    final hy = nodesPos[startNode]!['fy']! - nodesPos[endNode]!['fy']!;
    fScore[startNode] = math.sqrt(hx * hx + hy * hy);

    String? current;
    while (open.isNotEmpty) {
      // node in open with lowest fScore
      current = open.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);

      if (current == endNode) {
        final idPath = reconstructPath(cameFrom, current);
        // convert to fractional points
        final out = <Map<String, double>>[];
        for (final nid in idPath) {
          final n = nodesPos[nid];
          if (n != null) out.add({'fx': n['fx']!, 'fy': n['fy']!});
        }
        // anchor start & end exactly to room points
        if (out.isNotEmpty) {
          out.first['fx'] = startPoint['fx']!;
          out.first['fy'] = startPoint['fy']!;
          out[out.length - 1]['fx'] = endPoint['fx']!;
          out[out.length - 1]['fy'] = endPoint['fy']!;
        }
        return out;
      }

      open.remove(current);
      final neigh = adj[current] ?? {};
      for (final ent in neigh.entries) {
        final nbId = ent.key;
        final cost = ent.value;
        final tentativeG = gScore[current]! + cost;
        if (tentativeG < (gScore[nbId] ?? double.infinity)) {
          cameFrom[nbId] = current!;
          gScore[nbId] = tentativeG;
          final hx2 = nodesPos[nbId]!['fx']! - nodesPos[endNode]!['fx']!;
          final hy2 = nodesPos[nbId]!['fy']! - nodesPos[endNode]!['fy']!;
          fScore[nbId] = tentativeG + math.sqrt(hx2 * hx2 + hy2 * hy2);
          if (!open.contains(nbId)) open.add(nbId);
        }
      }
    }

    // If we reach here, no path found; fallback straight
    return [startPoint, endPoint];
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
