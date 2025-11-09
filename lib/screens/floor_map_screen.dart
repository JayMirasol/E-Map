import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_details_sheet.dart';

class FloorMapScreen extends StatefulWidget {
  final int floorNumber;
  final String floorTitle;
  final String imagePath;
  final String? initialStartRoomId;
  final String? initialDestinationRoomId;

  const FloorMapScreen({
    super.key,
    required this.floorNumber,
    required this.floorTitle,
    required this.imagePath,
    this.initialStartRoomId,
    this.initialDestinationRoomId,
  });

  @override
  State<FloorMapScreen> createState() => _FloorMapScreenState();
}

class _FloorMapScreenState extends State<FloorMapScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  // Start and destination rooms for pathfinding
  String? _startRoomId;
  String? _destinationRoomId;

  // Animation controllers
  late AnimationController _pathAnimationController;
  late AnimationController _markerAnimationController;
  late Animation<double> _pathAnimation;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation when this screen is opened
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Initialize with passed room IDs if available
    _startRoomId = widget.initialStartRoomId;
    _destinationRoomId = widget.initialDestinationRoomId;

    // Initialize animation controllers
    _pathAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Increased duration
      vsync: this,
    );

    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Path drawing animation with delay
    _pathAnimation = CurvedAnimation(
      parent: _pathAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut), // 30% delay
    );

    // If both start and destination are provided, start animations
    if (_startRoomId != null && _destinationRoomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markerAnimationController.repeat(reverse: true);
        _pathAnimationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pathAnimationController.dispose();
    _markerAnimationController.dispose();
    // Restore all orientations when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  void _resetSelection() {
    setState(() {
      _startRoomId = null;
      _destinationRoomId = null;
    });
    context.read<CampusProvider>().selectRoom(null);

    // Reset animations
    _pathAnimationController.reset();
    _markerAnimationController.reset();
  }

  // Simple pathfinding through waypoints using BFS
  List<String> _findPath(String startId, String endId, List rooms) {
    // Map of id -> Room for quick lookup
    final roomMap = {for (var r in rooms) r.id: r};

    // If either room doesn't exist or has no coordinates, return direct path
    if (!roomMap.containsKey(startId) || !roomMap.containsKey(endId)) {
      return [startId, endId];
    }

    // BFS queue: each entry is a path (list of room IDs)
    final queue = [
      [startId],
    ];
    final visited = <String>{startId};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      // Found destination
      if (current == endId) {
        return path;
      }

      final currentRoom = roomMap[current];
      if (currentRoom?.waypoints != null) {
        // Explore connected waypoints/rooms
        for (final nextId in currentRoom!.waypoints!) {
          if (!visited.contains(nextId) && roomMap.containsKey(nextId)) {
            visited.add(nextId);
            queue.add([...path, nextId]);
          }
        }
      }
    }

    // No path found through waypoints, return direct connection
    return [startId, endId];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (context, snap) {
        final provider = context.watch<CampusProvider>();
        final rooms = provider.rooms
            .where((r) => r.floor == widget.floorNumber)
            .toList();

        // Focus on selected room if any
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final id = provider.selectedRoomId;
          if (id != null) {
            final r = provider.roomById(id);
            if (r != null &&
                r.floor == widget.floorNumber &&
                r.fx != null &&
                r.fy != null) {
              _centerOnRoom(r.fx!, r.fy!);
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.floorTitle),
            actions: [
              IconButton(
                tooltip: 'Reset',
                icon: const Icon(Icons.close),
                onPressed: _resetSelection,
              ),
            ],
          ),
          body: Row(
            children: [
              // Map container - fixed on the left side
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey[200],
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onLongPressStart: (details) {
                          // Calculate fx/fy from tap position
                          final localPosition = details.localPosition;
                          final fx = (localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          final fy = (localPosition.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0);

                          // Show coordinates in a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Floor ${widget.floorNumber}: fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Copy',
                                onPressed: () {
                                  // Could add clipboard copy functionality here
                                },
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            // Floor plan image - ALWAYS visible
                            Image.asset(
                              widget.imagePath,
                              fit: BoxFit.contain,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, size: 64),
                                        SizedBox(height: 16),
                                        Text('Failed to load floor plan'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Path line between start and destination
                            if (_startRoomId != null &&
                                _destinationRoomId != null)
                              AnimatedBuilder(
                                animation: _pathAnimation,
                                builder: (context, child) {
                                  // Find path through waypoints
                                  final pathIds = _findPath(
                                    _startRoomId!,
                                    _destinationRoomId!,
                                    rooms,
                                  );

                                  // Convert path IDs to screen coordinates
                                  final pathPoints = pathIds
                                      .map(
                                        (id) => rooms.firstWhere(
                                          (r) => r.id == id,
                                          orElse: () => rooms.first,
                                        ),
                                      )
                                      .where(
                                        (r) => r.fx != null && r.fy != null,
                                      )
                                      .map(
                                        (r) => Offset(
                                          r.fx! * constraints.maxWidth,
                                          r.fy! * constraints.maxHeight,
                                        ),
                                      )
                                      .toList();

                                  // Need at least 2 points to draw
                                  if (pathPoints.length < 2) {
                                    return const SizedBox.shrink();
                                  }

                                  return CustomPaint(
                                    size: Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                    painter: PathLinePainter(
                                      pathPoints: pathPoints,
                                      animationProgress: _pathAnimation.value,
                                    ),
                                  );
                                },
                              ),
                            // Room markers
                            ...rooms.where((r) => r.fx != null && r.fy != null).map((
                              r,
                            ) {
                              // Hide waypoints completely - they're only for pathfinding
                              if (r.type == 'waypoint') {
                                return const SizedBox.shrink();
                              }

                              final selected =
                                  (provider.selectedRoomId == r.id);
                              final isStart = (_startRoomId == r.id);
                              final isDest = (_destinationRoomId == r.id);
                              final occupied = provider.isRoomOccupiedNow(r.id);

                              Color color;
                              double markerSize;
                              IconData markerIcon;

                              // Determine marker appearance based on state
                              if (isStart) {
                                color = Colors.green;
                                markerSize = 20;
                                markerIcon = Icons.place;
                              } else if (isDest) {
                                color = Colors.red;
                                markerSize = 20;
                                markerIcon = Icons.flag;
                              } else if (selected) {
                                color = Colors.purple;
                                markerSize = 18;
                                markerIcon = Icons.circle;
                              } else if (occupied) {
                                color = Colors.orange;
                                markerSize = 12;
                                markerIcon = Icons.circle;
                              } else {
                                color = Colors.blue;
                                markerSize = 12;
                                markerIcon = Icons.circle;
                              }

                              // Hide regular markers if no start room is selected
                              if (!isStart && !isDest && _startRoomId == null) {
                                return const SizedBox.shrink();
                              }

                              return Positioned(
                                left:
                                    r.fx! * constraints.maxWidth -
                                    (markerSize / 2),
                                top:
                                    r.fy! * constraints.maxHeight -
                                    (markerSize / 2),
                                child: AnimatedBuilder(
                                  animation: _markerAnimationController,
                                  builder: (context, child) {
                                    // Only start and destination markers should pulse
                                    final pulseScale = (isStart || isDest)
                                        ? 1.0 +
                                              (_markerAnimationController
                                                      .value *
                                                  0.15)
                                        : 1.0;

                                    return Transform.scale(
                                      scale: pulseScale,
                                      child: GestureDetector(
                                        onTap: () {
                                          provider.selectRoom(r.id);
                                          _showRoomDetails(
                                            context,
                                            r,
                                            provider,
                                          );
                                        },
                                        child: Tooltip(
                                          message: '${r.name} (${r.type})',
                                          child: Container(
                                            width: markerSize,
                                            height: markerSize,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                markerIcon,
                                                color: Colors.white,
                                                size: markerSize * 0.6,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Control panel on the right side
              Expanded(
                flex: 1,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Navigation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Start button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _startRoomId != null
                                ? Colors.green
                                : Colors.grey[300],
                            foregroundColor: _startRoomId != null
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _selectStartRoom(context, rooms),
                          icon: const Icon(Icons.place),
                          label: Text(
                            _startRoomId == null
                                ? 'Select Start'
                                : 'Start: ${rooms.firstWhere((r) => r.id == _startRoomId).name}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Destination button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _destinationRoomId != null
                                ? Colors.red
                                : Colors.grey[300],
                            foregroundColor: _destinationRoomId != null
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _startRoomId == null
                              ? null
                              : () => _selectDestinationRoom(context, rooms),
                          icon: const Icon(Icons.flag),
                          label: Text(
                            _destinationRoomId == null
                                ? 'Select Destination'
                                : 'Dest: ${rooms.firstWhere((r) => r.id == _destinationRoomId).name}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Room list button
                        OutlinedButton.icon(
                          onPressed: () {
                            _showRoomsList(context, rooms, provider);
                          },
                          icon: const Icon(Icons.list),
                          label: Text('View ${rooms.length} Rooms'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Legend
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Legend',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem(Colors.green, 'Start'),
                              _buildLegendItem(Colors.red, 'Destination'),
                              _buildLegendItem(Colors.orange, 'Occupied'),
                              _buildLegendItem(Colors.blue, 'Available'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _selectStartRoom(BuildContext context, List rooms) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RoomSelectionDialog(rooms: rooms, title: 'Select Start Room'),
    );
    if (selected != null) {
      setState(() {
        _startRoomId = selected;
        _destinationRoomId = null;
      });
      context.read<CampusProvider>().selectRoom(selected);

      // Trigger marker animation with repeat for pulsing effect
      _markerAnimationController.repeat(reverse: true);
    }
  }

  void _selectDestinationRoom(BuildContext context, List rooms) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RoomSelectionDialog(rooms: rooms, title: 'Select Destination Room'),
    );
    if (selected != null) {
      setState(() {
        _destinationRoomId = selected;
      });
      context.read<CampusProvider>().selectRoom(selected);

      // Trigger path animation
      _pathAnimationController.forward(from: 0.0);
    }
  }

  void _centerOnRoom(double fx, double fy) {
    // Not used in fixed layout but kept for compatibility
  }

  void _showRoomDetails(BuildContext context, room, CampusProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: SingleChildScrollView(
              controller: scrollController,
              child: RoomDetailsSheet(room: room),
            ),
          );
        },
      ),
    );
  }

  void _showRoomsList(
    BuildContext context,
    List rooms,
    CampusProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Rooms on ${widget.floorTitle}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final occupied = provider.isRoomOccupiedNow(room.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: occupied ? Colors.orange : Colors.blue,
                        child: Text(
                          room.name.replaceAll(RegExp(r'[^0-9]'), ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(room.name),
                      subtitle: Text(room.type),
                      trailing: Icon(
                        occupied ? Icons.event_busy : Icons.event_available,
                        color: occupied ? Colors.orange : Colors.green,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        provider.selectRoom(room.id);
                        if (room.fx != null && room.fy != null) {
                          _centerOnRoom(room.fx!, room.fy!);
                        }
                        _showRoomDetails(context, room, provider);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Room selection dialog
class _RoomSelectionDialog extends StatelessWidget {
  final List rooms;
  final String title;

  const _RoomSelectionDialog({required this.rooms, required this.title});

  @override
  Widget build(BuildContext context) {
    // Filter out waypoints - only show actual rooms to users
    final selectableRooms = rooms.where((r) => r.type != 'waypoint').toList();

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: selectableRooms.length,
          itemBuilder: (context, index) {
            final room = selectableRooms[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  room.name.replaceAll(RegExp(r'[^0-9]'), ''),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              title: Text(room.name),
              subtitle: Text(room.type),
              onTap: () {
                Navigator.pop(context, room.id);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Custom painter for the path line through waypoints
class PathLinePainter extends CustomPainter {
  final List<Offset> pathPoints;
  final double animationProgress;

  PathLinePainter({required this.pathPoints, this.animationProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;

    // Calculate total path length
    double totalLength = 0;
    final segmentLengths = <double>[];
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final length = (pathPoints[i + 1] - pathPoints[i]).distance;
      segmentLengths.add(length);
      totalLength += length;
    }

    // Calculate how much of the path to draw based on animation
    final targetLength = totalLength * animationProgress;

    // Paint for green (first half of total path)
    final greenPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Paint for red (second half of total path)
    final redPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw path segments
    double accumulatedLength = 0;
    final halfLength = totalLength / 2;

    for (int i = 0; i < pathPoints.length - 1; i++) {
      final segmentLength = segmentLengths[i];
      final segmentStart = pathPoints[i];
      final segmentEnd = pathPoints[i + 1];

      // Check if we should draw this segment
      if (accumulatedLength < targetLength) {
        final remainingTarget = targetLength - accumulatedLength;
        final drawLength = remainingTarget < segmentLength
            ? remainingTarget
            : segmentLength;
        final t = drawLength / segmentLength;

        final drawEnd = Offset(
          segmentStart.dx + (segmentEnd.dx - segmentStart.dx) * t,
          segmentStart.dy + (segmentEnd.dy - segmentStart.dy) * t,
        );

        // Determine color based on position in total path
        final paint = (accumulatedLength + segmentLength / 2) < halfLength
            ? greenPaint
            : redPaint;

        canvas.drawLine(segmentStart, drawEnd, paint);

        // Draw arrow at the end if this is the last segment being drawn
        if (drawLength < segmentLength || i == pathPoints.length - 2) {
          if (animationProgress > 0.8) {
            _drawArrowHead(canvas, segmentStart, drawEnd, paint);
          }
          break;
        }
      }

      accumulatedLength += segmentLength;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 12.0;
    final angle = (to - from).direction;

    final arrowPath = Path();
    arrowPath.moveTo(to.dx, to.dy);
    arrowPath.lineTo(
      to.dx - arrowSize * 0.866 * (to.dx - from.dx).sign,
      to.dy - arrowSize * 0.5,
    );
    arrowPath.lineTo(
      to.dx - arrowSize * 0.866 * (to.dx - from.dx).sign,
      to.dy + arrowSize * 0.5,
    );
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    // Rotate arrow to point in the right direction
    canvas.save();
    canvas.translate(to.dx, to.dy);
    canvas.rotate(angle);
    canvas.translate(-to.dx, -to.dy);

    final properArrow = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize, to.dy - arrowSize / 2)
      ..lineTo(to.dx - arrowSize, to.dy + arrowSize / 2)
      ..close();

    canvas.drawPath(properArrow, arrowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PathLinePainter oldDelegate) {
    return oldDelegate.pathPoints != pathPoints ||
        oldDelegate.animationProgress != animationProgress;
  }
}
