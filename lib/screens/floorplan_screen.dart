// lib/screens/floorplan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../models/room.dart';
import '../widgets/room_search.dart';
import '../widgets/room_details_sheet.dart';

/// FloorplanScreen - interactive CCA floorplan for 1F and 2F.
/// Shows pins, supports start/destination, pathfinding (A*), waypoints, and path arrows.
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
              title: const Text('ICSLIS Floorplan'),
              bottom: TabBar(
                isScrollable: false,
                tabs: floors.map((f) => Tab(text: '${f}F')).toList(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Search rooms',
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final selected = await showSearch<Room?>(
                      context: context,
                      delegate: RoomSearchDelegate(source: rooms),
                    );
                    if (selected != null) {
                      _openRoomSheet(context, selected);
                    }
                  },
                ),
              ],
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

  static void _openRoomSheet(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          child: RoomDetailsSheet(room: room),
        ),
      ),
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

class _FloorCanvasState extends State<_FloorCanvas>
    with TickerProviderStateMixin {
  final TransformationController _tc = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  Room? _startRoom;
  Room? _endRoom;

  // store fractional waypoints (0..1), not px — convert to px in build()
  final List<Offset> _fracWaypoints = [];
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
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _startRoom = selected;
        _endRoom = null;
        _fracWaypoints.clear();
        _addingWaypoint = false;
      });
    }
  }

  Future<void> _chooseDest() async {
    final selected = await showSearch<Room?>(
      context: context,
      delegate: RoomSearchDelegate(source: widget.rooms),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _endRoom = selected;
        _addingWaypoint = false;
      });

      // If we have both start & end, request provider for graph path
      if (_startRoom != null && _endRoom != null) {
        final provider = context.read<CampusProvider>();
        final nodes = await provider.findPathBetweenRooms(
          _startRoom!.id,
          _endRoom!.id,
        );
        if (nodes.isNotEmpty) {
          setState(() {
            _fracWaypoints.clear();
            for (final p in nodes) {
              final fx = (p['fx'] ?? 0.5).clamp(0.0, 1.0);
              final fy = (p['fy'] ?? 0.5).clamp(0.0, 1.0);
              _fracWaypoints.add(Offset(fx, fy));
            }
          });
        } else {
          // fallback to straight line fractional points
          setState(() {
            _fracWaypoints.clear();
            _fracWaypoints.add(
              Offset(_startRoom!.fx ?? 0.5, _startRoom!.fy ?? 0.5),
            );
            _fracWaypoints.add(
              Offset(_endRoom!.fx ?? 0.5, _endRoom!.fy ?? 0.5),
            );
          });
        }
      }
    }
  }

  void _clearPath() {
    setState(() {
      _startRoom = null;
      _endRoom = null;
      _fracWaypoints.clear();
      _addingWaypoint = false;
    });
  }

  Offset? _roomOffset(Room? r, double w, double h) {
    if (r == null || r.fx == null || r.fy == null) return null;
    return Offset(r.fx! * w, r.fy! * h);
  }

  List<Offset> _buildPathPointsPx(double w, double h) {
    final points = <Offset>[];
    // Start anchor: room point if present
    if (_fracWaypoints.isNotEmpty) {
      for (final f in _fracWaypoints) {
        points.add(Offset(f.dx * w, f.dy * h));
      }
    } else {
      final start = _roomOffset(_startRoom, w, h);
      final end = _roomOffset(_endRoom, w, h);
      if (start != null) points.add(start);
      if (end != null) points.add(end);
    }
    return points;
  }

  Widget _buildHotspot(Room r, Size parentSize, Color color) {
    final dx = (r.fx ?? 0.5) * parentSize.width;
    final dy = (r.fy ?? 0.5) * parentSize.height;

    return Positioned(
      left: dx - 14,
      top: dy - 14,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, sc) => SingleChildScrollView(
                controller: sc,
                child: RoomDetailsSheet(room: r),
              ),
            ),
          );
        },
        onLongPress: () {
          final fx = r.fx ?? 0;
          final fy = r.fy ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Room ${r.name} fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
              ),
            ),
          );
        },
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

        final pathPoints = _buildPathPointsPx(w, h);

        return Stack(
          children: [
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

                    // route with arrows
                    if (pathPoints.length >= 2)
                      CustomPaint(
                        painter: PathWithArrowsPainter(
                          points: pathPoints,
                          color: Colors.green,
                        ),
                        size: Size(w, h),
                      ),

                    if (hasStart)
                      _buildHotspot(_startRoom!, Size(w, h), Colors.green),
                    if (hasEnd)
                      _buildHotspot(_endRoom!, Size(w, h), Colors.red),

                    // Waypoint markers removed by request (show path only)

                    // draw simple pins for rooms
                    ...widget.rooms
                        .where((r) => r != _startRoom && r != _endRoom)
                        .map((r) {
                          final dx = (r.fx ?? 0.5) * w;
                          final dy = (r.fy ?? 0.5) * h;
                          return Positioned(
                            left: dx - 12,
                            top: dy - 12,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  builder: (_) => DraggableScrollableSheet(
                                    initialChildSize: 0.5,
                                    minChildSize: 0.3,
                                    maxChildSize: 0.9,
                                    expand: false,
                                    builder: (ctx, sc) => SingleChildScrollView(
                                      controller: sc,
                                      child: RoomDetailsSheet(room: r),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.place,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ),

            // Long-press capture and waypoint placement
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
                    setState(() {
                      _fracWaypoints.add(Offset(fx, fy));
                      _addingWaypoint = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waypoint added.')),
                    );
                  } else {
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

            // Controls
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
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
                  const SizedBox(width: 8),
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
                                _fracWaypoints.isNotEmpty)
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

/// Painter that draws a polyline only (no arrows).
class PathWithArrowsPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  PathWithArrowsPainter({required this.points, this.color = Colors.green});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PathWithArrowsPainter old) {
    if (old.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (old.points[i] != points[i]) return true;
    }
    return false;
  }
}
