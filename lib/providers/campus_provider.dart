// lib/providers/campus_provider.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../models/floor_graph.dart';
import '../core/pathfinding.dart';
import 'package:flutter/material.dart';
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
  Map<String, dynamic> _manualRoutes = {};
  // In-progress manual route draft shared across floors/screens
  String? _draftStartId;
  String? _draftEndId;
  final Map<int, List<Map<String, double>>> _manualDraftByFloor = {};

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
    await _loadManualRoutes();
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

  Future<void> _loadManualRoutes() async {
    try {
      _manualRoutes = await LocalStore.readManualRoutes();
    } catch (_) {
      _manualRoutes = {};
    }
    if (kDebugMode) {
      debugPrint('Manual routes loaded: ${_manualRoutes.keys.length} keys');
    }
  }

  Future<void> saveManualRoute(
    String startRoomId,
    String endRoomId,
    List<Map<String, dynamic>> segments,
  ) async {
    // Save each floor segment separately with floor-specific keys
    for (final seg in segments) {
      final floor = seg['floor'] as int;
      final pts = seg['points'] as List;
      final key = '$floor:$startRoomId->$endRoomId';
      _manualRoutes[key] = [seg]; // Store as single-floor segment

      // Also store reverse for convenience
      final revPts = pts.reversed.toList();
      final revKey = '$floor:$endRoomId->$startRoomId';
      _manualRoutes[revKey] = [
        {'floor': floor, 'points': revPts},
      ];
    }

    await LocalStore.writeManualRoutes(_manualRoutes);
    notifyListeners();
  }

  // -------- Manual route draft API (for cross-floor editing) --------

  void beginManualRoute(String startRoomId, String endRoomId) {
    if (_draftStartId == startRoomId && _draftEndId == endRoomId) return;
    _draftStartId = startRoomId;
    _draftEndId = endRoomId;
    _manualDraftByFloor.clear();
    notifyListeners();
  }

  void addManualDraftPoint(int floor, double fx, double fy) {
    if (_draftStartId == null || _draftEndId == null) return;
    final list = _manualDraftByFloor.putIfAbsent(
      floor,
      () => <Map<String, double>>[],
    );
    list.add({'fx': fx, 'fy': fy});
    notifyListeners();
  }

  void undoManualDraftPoint(int floor) {
    final list = _manualDraftByFloor[floor];
    if (list != null && list.isNotEmpty) {
      list.removeLast();
      notifyListeners();
    }
  }

  void clearManualDraftFloor(int floor) {
    _manualDraftByFloor.remove(floor);
    notifyListeners();
  }

  /// Delete a saved manual route for a specific floor
  Future<void> deleteManualRouteForFloor(
    String startRoomId,
    String endRoomId,
    int floor,
  ) async {
    final key = '$floor:$startRoomId->$endRoomId';
    final revKey = '$floor:$endRoomId->$startRoomId';
    _manualRoutes.remove(key);
    _manualRoutes.remove(revKey);
    await LocalStore.writeManualRoutes(_manualRoutes);
    notifyListeners();
  }

  /// Check if a manual route exists for a specific floor
  bool hasManualRouteForFloor(String startRoomId, String endRoomId, int floor) {
    final key = '$floor:$startRoomId->$endRoomId';
    return _manualRoutes.containsKey(key);
  }

  List<Map<String, double>> draftPointsForFloor(int floor) {
    return List<Map<String, double>>.from(
      _manualDraftByFloor[floor] ?? const [],
    );
  }

  bool get hasDraft =>
      _draftStartId != null &&
      _draftEndId != null &&
      _manualDraftByFloor.isNotEmpty;

  Future<void> saveManualDraft() async {
    if (!hasDraft) return;
    final startId = _draftStartId!;
    final endId = _draftEndId!;
    final sr = roomById(startId);
    final er = roomById(endId);
    if (sr == null || er == null) return;

    // Order floors according to direction: start floor first, then others
    final floors = _manualDraftByFloor.keys.toSet();
    final ordered = <int>[];
    if (sr.floor != null && floors.contains(sr.floor)) ordered.add(sr.floor!);
    for (final f in floors) {
      if (!ordered.contains(f)) ordered.add(f);
    }

    final segments = <Map<String, dynamic>>[];
    for (final f in ordered) {
      final pts = _manualDraftByFloor[f];
      if (pts == null || pts.length < 2) continue;
      segments.add({'floor': f, 'points': List<Map<String, double>>.from(pts)});
    }
    if (segments.isEmpty) return;

    await saveManualRoute(startId, endId, segments);

    // Clear draft after save
    _draftStartId = null;
    _draftEndId = null;
    _manualDraftByFloor.clear();
    notifyListeners();
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

  // ---------- Cross-floor routing (stairs/elevators) ----------

  /// Compute a cross-floor route from startRoomId to endRoomId.
  /// Returns an ordered list of floor-segment polylines where each segment
  /// contains fractional points (fx, fy) normalized to the corresponding
  /// floor image coordinate space.
  ///
  /// segments: [ { 'floor': 1, 'points': [ {'fx':..,'fy':..}, ... ] }, ... ]
  Future<List<Map<String, dynamic>>> computeCrossFloorRoute(
    String startRoomId,
    String endRoomId, {
    double verticalPenalty = 0.15,
  }) async {
    final startRoom = roomById(startRoomId);
    final endRoom = roomById(endRoomId);
    if (startRoom == null || endRoom == null) return [];

    final sf = startRoom.floor;
    final ef = endRoom.floor;
    if (sf == null || ef == null) return [];

    // Check for floor-specific manual routes
    final segments = <Map<String, dynamic>>[];

    // Determine which floors are involved
    final minFloor = math.min(sf, ef);
    final maxFloor = math.max(sf, ef);
    final floorsInRoute = List<int>.generate(
      maxFloor - minFloor + 1,
      (i) => minFloor + i,
    );

    // Try to find manual routes for each floor
    bool foundAllManualRoutes = true;
    for (final floor in floorsInRoute) {
      final floorKey = '$floor:$startRoomId->$endRoomId';
      final manual = _manualRoutes[floorKey];

      if (manual is List && manual.isNotEmpty) {
        // Add this floor's manual segment
        final seg = manual.first as Map;
        segments.add({
          'floor': seg['floor'],
          'points': (seg['points'] as List)
              .map(
                (p) => {
                  'fx': (p['fx'] as num).toDouble(),
                  'fy': (p['fy'] as num).toDouble(),
                },
              )
              .toList(),
          'instruction': floor == sf
              ? 'Follow path to connector'
              : floor == ef
              ? 'Follow path to ${endRoom.name}'
              : 'Continue through floor $floor',
          'connector': floor < maxFloor ? 'Stair_L' : null,
        });
      } else {
        foundAllManualRoutes = false;
        break;
      }
    }

    if (foundAllManualRoutes && segments.isNotEmpty) {
      return segments;
    }

    // Fall back to old non-floor-specific manual route (for backward compatibility)
    final oldKey = '$startRoomId->$endRoomId';
    final oldManual = _manualRoutes[oldKey];
    if (oldManual is List) {
      final cleaned = oldManual
          .whereType<Map>()
          .map(
            (m) => {
              'floor': m['floor'],
              'points': (m['points'] as List)
                  .map(
                    (p) => {
                      'fx': (p['fx'] as num).toDouble(),
                      'fy': (p['fy'] as num).toDouble(),
                    },
                  )
                  .toList(),
            },
          )
          .toList();
      if (cleaned.isNotEmpty) return cleaned;
    }

    // Same-floor: reuse single-floor router for best fidelity.
    if (sf == ef) {
      final pts = await findPathBetweenRooms(startRoomId, endRoomId);
      return [
        {
          'floor': sf,
          'points': pts,
          'instruction':
              'Proceed on Floor $sf from ${startRoom.name} to ${endRoom.name}',
        },
      ];
    }

    // Candidate vertical connectors that exist across floors (by common node id)
    const connectorIds = ['Stair_L', 'Stair_R'];

    // Helper: choose attach node for a room on a floor graph
    String _attachNodeForRoom(FloorGraph g, Room r) {
      // Prefer explicit door mapping by room name/id
      final byName = g.roomToDoorNode[r.name];
      if (byName != null && g.nodes.containsKey(byName)) return byName;
      final byId = g.roomToDoorNode[r.id];
      if (byId != null && g.nodes.containsKey(byId)) return byId;
      // Fallback to nearest corridor/any node to room center
      final fx = r.fx ?? 0.5, fy = r.fy ?? 0.5;
      String? best;
      var bestD = double.infinity;
      g.nodes.forEach((id, n) {
        final dx = n.fx - fx, dy = n.fy - fy;
        final d2 = dx * dx + dy * dy;
        if (d2 < bestD) {
          bestD = d2;
          best = id;
        }
      });
      return best ?? g.nodes.keys.first;
    }

    // Helper: sum Euclidean length of a node-id path on a floor graph
    double _pathCost(FloorGraph g, List<String> nodeIds) {
      if (nodeIds.length < 2) return 0.0;
      double sum = 0.0;
      for (int i = 0; i < nodeIds.length - 1; i++) {
        final a = g.nodes[nodeIds[i]]!;
        final b = g.nodes[nodeIds[i + 1]]!;
        final dx = a.fx - b.fx, dy = a.fy - b.fy;
        sum += math.sqrt(dx * dx + dy * dy);
      }
      return sum;
    }

    // Try each connector and pick the cheapest viable route.
    List<Map<String, dynamic>>? bestSegments;
    double bestTotal = double.infinity;

    for (final connectorId in connectorIds) {
      // Ensure connector node exists on both floors involved (and any intermediate floors)
      bool connectorsExist = true;
      for (int f = math.min(sf, ef); f <= math.max(sf, ef); f++) {
        final gf = _floorGraphs[f];
        if (gf == null || !gf.nodes.containsKey(connectorId)) {
          connectorsExist = false;
          break;
        }
      }
      if (!connectorsExist) continue;

      final gStart = _floorGraphs[sf]!;
      final gEnd = _floorGraphs[ef]!;

      final startAttach = _attachNodeForRoom(gStart, startRoom);
      final endAttach = _attachNodeForRoom(gEnd, endRoom);

      final pathStart = Pathfinder.aStar(gStart, startAttach, connectorId);
      if (pathStart.isEmpty) continue;
      final pathEnd = Pathfinder.aStar(gEnd, connectorId, endAttach);
      if (pathEnd.isEmpty) continue;

      final cost =
          _pathCost(gStart, pathStart) +
          (verticalPenalty * (ef - sf).abs()) +
          _pathCost(gEnd, pathEnd);

      if (cost < bestTotal) {
        bestTotal = cost;

        // Build segments as polylines with anchors at real room centers
        final segments = <Map<String, dynamic>>[];

        // Start floor segment points
        final startPts = <Map<String, double>>[];
        startPts.add({'fx': startRoom.fx ?? 0.5, 'fy': startRoom.fy ?? 0.5});
        for (final nid in pathStart) {
          final n = gStart.nodes[nid]!;
          startPts.add({'fx': n.fx, 'fy': n.fy});
        }
        segments.add({
          'floor': sf,
          'points': startPts,
          'instruction': 'Go to $connectorId and take it to Floor $ef',
          'connector': connectorId,
        });

        // End floor segment points
        final endPts = <Map<String, double>>[];
        // start at connector on end floor
        final nConn = gEnd.nodes[connectorId]!;
        endPts.add({'fx': nConn.fx, 'fy': nConn.fy});
        for (final nid in pathEnd.skip(1)) {
          final n = gEnd.nodes[nid]!;
          endPts.add({'fx': n.fx, 'fy': n.fy});
        }
        endPts.add({'fx': endRoom.fx ?? 0.5, 'fy': endRoom.fy ?? 0.5});
        segments.add({
          'floor': ef,
          'points': endPts,
          'instruction': 'Proceed to ${endRoom.name}',
          'connector': connectorId,
        });

        bestSegments = segments;
      }
    }

    return bestSegments ?? [];
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
