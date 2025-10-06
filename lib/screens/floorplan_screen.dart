import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../models/room.dart';
import '../widgets/room_search.dart';

class FloorplanScreen extends StatelessWidget {
  const FloorplanScreen({super.key});

  static const floors = [1, 2, 3, 4];
  static String imageFor(int floor) => 'assets/images/floor_$floor.png';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final rooms = context.watch<CampusProvider>().rooms;

        return DefaultTabController(
          length: floors.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Floorplan'),
              bottom: TabBar(
                isScrollable: false,
                tabs: floors.map((f) => Tab(text: '${f}F')).toList(),
              ),
            ),
            body: TabBarView(
              children: floors.map((f) {
                final roomsOnFloor = rooms.where((r) => r.floor == f).toList();
                return _FloorCanvas(
                  floor: f,
                  imagePath: imageFor(f),
                  rooms: roomsOnFloor,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _FloorCanvas extends StatefulWidget {
  final int floor;
  final String imagePath;
  final List<Room> rooms;

  const _FloorCanvas({
    required this.floor,
    required this.imagePath,
    required this.rooms,
  });

  @override
  State<_FloorCanvas> createState() => _FloorCanvasState();
}

class _FloorCanvasState extends State<_FloorCanvas> {
  final TransformationController _tc = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  Room? _startRoom;
  Room? _endRoom;

  // NEW: waypoint support
  final List<Offset> _waypoints =
      []; // in canvas logical px (after fx/fy -> px)
  bool _addingWaypoint = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _chooseStart() async {
    final selected = await showSearch<Room?>(
      context: context,
      delegate: RoomSearchDelegate(source: widget.rooms),
    );
    if (selected != null) {
      setState(() {
        _startRoom = selected;
        _endRoom = null; // reset destination when start changes
        _waypoints.clear(); // reset path shape
        _addingWaypoint = false;
      });
    }
  }

  Future<void> _chooseDest() async {
    final selected = await showSearch<Room?>(
      context: context,
      delegate: RoomSearchDelegate(source: widget.rooms),
    );
    if (selected != null) {
      setState(() {
        _endRoom = selected;
        // keep waypoints
        _addingWaypoint = false;
      });
    }
  }

  // Optional helper: add a waypoint at a chosen room center (via search)
  // Future<void> _addWaypointFromRoom() async {
  //   final selected = await showSearch<Room?>(
  //     context: context,
  //     delegate: RoomSearchDelegate(source: widget.rooms),
  //   );
  //   if (selected != null && selected.fx != null && selected.fy != null) {
  //     final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
  //     if (box == null) return;
  //     final size = box.size;
  //     setState(() {
  //       _waypoints.add(
  //         Offset(selected.fx! * size.width, selected.fy! * size.height),
  //       );
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'This room has no fx/fy yet. Long-press to capture coordinates.',
  //         ),
  //       ),
  //     );
  //   }
  // }

  void _clearPath() {
    setState(() {
      _startRoom = null;
      _endRoom = null;
      _waypoints.clear();
      _addingWaypoint = false;
    });
  }

  Offset? _roomOffset(Room? r, double w, double h) {
    if (r == null || r.fx == null || r.fy == null) return null;
    return Offset(r.fx! * w, r.fy! * h);
  }

  Widget _buildHotspot(Room r, Size parentSize, Color color) {
    final dx = (r.fx ?? 0) * parentSize.width;
    final dy = (r.fy ?? 0) * parentSize.height;

    return Positioned(
      left: dx - 14,
      top: dy - 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.place, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              r.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Build a simple polyline: start -> waypoints -> end
  List<Offset> _buildPathPoints(double w, double h) {
    final points = <Offset>[];
    final start = _roomOffset(_startRoom, w, h);
    final end = _roomOffset(_endRoom, w, h);

    if (start != null) points.add(start);
    points.addAll(_waypoints); // already in canvas pixel coords
    if (end != null) points.add(end);

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final startPos = _roomOffset(_startRoom, w, h);
        final endPos = _roomOffset(_endRoom, w, h);

        final hasStart = _startRoom != null && startPos != null;
        final hasEnd = _endRoom != null && endPos != null;

        final pathPoints = _buildPathPoints(w, h);

        return Stack(
          children: [
            // Map + overlays
            InteractiveViewer(
              transformationController: _tc,
              minScale: 0.7,
              maxScale: 6,
              child: SizedBox.expand(
                key: _canvasKey,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                    ),

                    // Polyline path (start -> waypoints -> end)
                    if (pathPoints.length >= 2)
                      CustomPaint(
                        painter: _PolylinePainter(points: pathPoints),
                        size: Size(w, h),
                      ),

                    // Show ONLY the selected Start and Destination
                    if (hasStart)
                      _buildHotspot(_startRoom!, Size(w, h), Colors.green),
                    if (hasEnd)
                      _buildHotspot(_endRoom!, Size(w, h), Colors.red),

                    // Optional: draw small dots for waypoints
                    ..._waypoints.map(
                      (pt) => Positioned(
                        left: pt.dx - 6,
                        top: pt.dy - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Long-press handler:
            // - if adding waypoint: drop a waypoint at pressed spot (in canvas logical px)
            // - else: calibration readout
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (details) {
                  final box =
                      _canvasKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (box == null) return;

                  final localOnCanvas = box.globalToLocal(
                    details.globalPosition,
                  );
                  final inv = Matrix4.inverted(_tc.value);
                  final logical = MatrixUtils.transformPoint(
                    inv,
                    localOnCanvas,
                  );

                  final fx = (logical.dx / w).clamp(0.0, 1.0);
                  final fy = (logical.dy / h).clamp(0.0, 1.0);

                  if (_addingWaypoint) {
                    // add waypoint at logical px position
                    setState(() {
                      _waypoints.add(Offset(fx * w, fy * h));
                      _addingWaypoint = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waypoint added.')),
                    );
                  } else {
                    // calibration readout
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Floor ${widget.floor} fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // Controls row
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Choose Start (green when selected)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _startRoom != null
                            ? Colors.green
                            : null,
                        foregroundColor: _startRoom != null
                            ? Colors.white
                            : null,
                      ),
                      onPressed: _chooseStart,
                      child: Text(
                        _startRoom == null
                            ? 'Start'
                            : 'Start: ${_startRoom!.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Choose Destination (red when selected)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _endRoom != null ? Colors.red : null,
                        foregroundColor: _endRoom != null ? Colors.white : null,
                      ),
                      onPressed: _startRoom == null ? null : _chooseDest,
                      child: Text(
                        _endRoom == null
                            ? 'Destination'
                            : 'Dest: ${_endRoom!.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // NEW: Add Waypoint (enabled when start is set)
                  SizedBox(
                    width: 56,
                    height: 48,
                    child: Tooltip(
                      message: _startRoom == null
                          ? 'Choose a Start first'
                          : (_addingWaypoint
                                ? 'Long-press to drop waypoint'
                                : 'Add Waypoint'),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _addingWaypoint
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _startRoom == null
                            ? null
                            : () {
                                setState(() {
                                  _addingWaypoint = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Long-press on the map to place a waypoint',
                                    ),
                                  ),
                                );
                              },
                        child: const Icon(Icons.add_road),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),

                  // // (Optional) Add waypoint from a room center, via search
                  // SizedBox(
                  //   width: 56,
                  //   height: 48,
                  //   child: Tooltip(
                  //     message: 'Add waypoint from room',
                  //     child: ElevatedButton(
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.grey.shade200,
                  //         foregroundColor: Colors.black87,
                  //         padding: EdgeInsets.zero,
                  //       ),
                  //       onPressed: _startRoom == null
                  //           ? null
                  //           : _addWaypointFromRoom,
                  //       child: const Icon(Icons.add_location_alt),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 8),

                  // Clear Path
                  SizedBox(
                    width: 56,
                    height: 48,
                    child: Tooltip(
                      message: 'Clear Path',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed:
                            (_startRoom != null ||
                                _endRoom != null ||
                                _waypoints.isNotEmpty)
                            ? _clearPath
                            : null,
                        child: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PolylinePainter extends CustomPainter {
  final List<Offset> points;

  _PolylinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PolylinePainter old) {
    if (old.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (old.points[i] != points[i]) return true;
    }
    return false;
  }
}
