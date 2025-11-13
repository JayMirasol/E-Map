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

  // Cross-floor route cache: floor -> list of fractional points
  final Map<int, List<Offset>> _routeByFloor = {};
  final List<String> _routeInstructions = [];
  final Map<int, String> _connectorByFloor = {};
  final List<int> _routeFloorOrder = [];
  bool _autoSwitchDone = false;
  bool _showSwitchOverlay = false;
  // Manual route editing
  bool _editMode = false;

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

    // When path animation completes, auto-switch to next floor if needed
    _pathAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onPathAnimationCompleted();
      }
    });

    // If both start and destination are provided, start animations
    if (_startRoomId != null && _destinationRoomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Check if there's an active draft session
        final provider = context.read<CampusProvider>();
        if (provider.hasDraft) {
          // Continue edit mode from another floor
          setState(() => _editMode = true);
        } else {
          // Normal navigation mode
          await _recomputeRoute();
          _markerAnimationController.repeat(reverse: true);
          _pathAnimationController.forward();
        }
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

  Future<void> _recomputeRoute() async {
    if (_startRoomId == null || _destinationRoomId == null) return;
    final provider = context.read<CampusProvider>();
    final segments = await provider.computeCrossFloorRoute(
      _startRoomId!,
      _destinationRoomId!,
    );
    _routeByFloor.clear();
    _routeInstructions.clear();
    _connectorByFloor.clear();
    _routeFloorOrder.clear();
    for (final seg in segments) {
      final floor = seg['floor'] as int;
      _routeFloorOrder.add(floor);
      final pts = (seg['points'] as List)
          .cast<Map>()
          .map(
            (m) => Offset(
              (m['fx'] as num).toDouble(),
              (m['fy'] as num).toDouble(),
            ),
          )
          .toList();
      _routeByFloor[floor] = pts;
      if (seg['instruction'] is String) {
        _routeInstructions.add(seg['instruction'] as String);
      }
      if (seg['connector'] is String) {
        _connectorByFloor[floor] = seg['connector'] as String;
      }
    }
    _autoSwitchDone = false;
    _showSwitchOverlay = false;
    setState(() {});
  }

  void _onPathAnimationCompleted() {
    // If the route includes multiple floors and this is not the last segment,
    // automatically switch to the next floor after a short overlay.
    if (_editMode) return; // don't auto-switch while editing
    if (_autoSwitchDone) return;
    if (_routeFloorOrder.isEmpty) return;
    final floors = List<int>.from(_routeFloorOrder);
    final currentIndex = floors.indexOf(widget.floorNumber);
    if (currentIndex == -1) return;
    final isLast = currentIndex >= floors.length - 1;
    if (isLast) return;

    // Show a brief overlay then push the next floor
    setState(() => _showSwitchOverlay = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final nextFloor = floors[currentIndex + 1];
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => FloorMapScreen(
            floorNumber: nextFloor,
            floorTitle: nextFloor == 1
                ? 'Ground Floor'
                : nextFloor == 2
                ? '2nd Floor: Main Building'
                : nextFloor == 3
                ? '3rd Floor'
                : '4th Floor',
            imagePath: nextFloor == 1
                ? 'assets/images/1ST FLOOR.jpg'
                : nextFloor == 2
                ? 'assets/images/2ND FLOOR.jpg'
                : nextFloor == 3
                ? 'assets/images/3RD FLOOR.jpg'
                : 'assets/images/4TH FLOOR.jpg',
            initialStartRoomId: _startRoomId,
            initialDestinationRoomId: _destinationRoomId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
        ),
      );
      _autoSwitchDone = true;
      _showSwitchOverlay = false;
    });
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

                          if (_editMode) {
                            context.read<CampusProvider>().addManualDraftPoint(
                              widget.floorNumber,
                              fx,
                              fy,
                            );
                          } else {
                            // Show coordinates in a snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Floor ${widget.floorNumber}: fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Copy',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          }
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
                            // Path polyline for the CURRENT floor only
                            if (_startRoomId != null &&
                                _destinationRoomId != null)
                              AnimatedBuilder(
                                animation: _pathAnimation,
                                builder: (context, child) {
                                  final pts = _editMode
                                      ? context
                                            .watch<CampusProvider>()
                                            .draftPointsForFloor(
                                              widget.floorNumber,
                                            )
                                            .map(
                                              (m) => Offset(m['fx']!, m['fy']!),
                                            )
                                            .toList()
                                      : _routeByFloor[widget.floorNumber];
                                  if (pts == null || pts.length < 2) {
                                    return const SizedBox.shrink();
                                  }
                                  final scaled = pts
                                      .map(
                                        (p) => Offset(
                                          p.dx * constraints.maxWidth,
                                          p.dy * constraints.maxHeight,
                                        ),
                                      )
                                      .toList();
                                  return CustomPaint(
                                    size: Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                    painter: PathLinePainter(
                                      pathPoints: scaled,
                                      animationProgress: _pathAnimation.value,
                                    ),
                                  );
                                },
                              ),
                            // Pulsing stair marker on this floor (if any)
                            Builder(
                              builder: (_) {
                                final connectorId =
                                    _connectorByFloor[widget.floorNumber];
                                if (connectorId == null)
                                  return const SizedBox.shrink();
                                final provider = context.read<CampusProvider>();
                                final g = provider.graphForFloor(
                                  widget.floorNumber,
                                );
                                if (g == null ||
                                    !g.nodes.containsKey(connectorId)) {
                                  return const SizedBox.shrink();
                                }
                                final n = g.nodes[connectorId]!;
                                final px = n.fx * constraints.maxWidth;
                                final py = n.fy * constraints.maxHeight;
                                return Positioned(
                                  left: px - 14,
                                  top: py - 14,
                                  child: AnimatedBuilder(
                                    animation: _markerAnimationController,
                                    builder: (context, child) {
                                      final scale =
                                          1.0 +
                                          (_markerAnimationController.value *
                                              0.2);
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.9,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.25,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.stairs,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            // Floor switch overlay when transitioning
                            if (_showSwitchOverlay)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.25),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.stairs,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Switching to next floor...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                        // Manual route editor controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.gesture, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Manual Route',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Switch(
                                    value: _editMode,
                                    onChanged:
                                        (_startRoomId != null &&
                                            _destinationRoomId != null)
                                        ? (v) {
                                            setState(() => _editMode = v);
                                            if (v) {
                                              context
                                                  .read<CampusProvider>()
                                                  .beginManualRoute(
                                                    _startRoomId!,
                                                    _destinationRoomId!,
                                                  );
                                            }
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (_editMode) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_location,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Editing Floor ${widget.floorNumber}: ${provider.draftPointsForFloor(widget.floorNumber).length} points',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Show if a saved route already exists for this floor
                                if (_startRoomId != null &&
                                    _destinationRoomId != null &&
                                    provider.hasManualRouteForFloor(
                                      _startRoomId!,
                                      _destinationRoomId!,
                                      widget.floorNumber,
                                    )) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          size: 16,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Floor ${widget.floorNumber} already has a saved path',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[900],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Delete Saved Path?',
                                                ),
                                                content: Text(
                                                  'This will delete the saved path for Floor ${widget.floorNumber} only. '
                                                  'Other floors will not be affected.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await provider
                                                  .deleteManualRouteForFloor(
                                                    _startRoomId!,
                                                    _destinationRoomId!,
                                                    widget.floorNumber,
                                                  );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Deleted saved path for Floor ${widget.floorNumber}',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _editMode
                                    ? 'Long-press on the map to add points. Create separate paths for each floor involved in the route.'
                                    : 'Enable to manually draw a custom path (overrides auto-routing).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (_editMode) ...[
                                const SizedBox(height: 12),
                                // Show status of all floors
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Floor Status:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        children: [1, 2, 3, 4].map((f) {
                                          final points = provider
                                              .draftPointsForFloor(f);
                                          final hasPoints = points.isNotEmpty;
                                          return Chip(
                                            avatar: Icon(
                                              hasPoints
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              size: 16,
                                              color: hasPoints
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              'F$f: ${points.length}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                            backgroundColor:
                                                f == widget.floorNumber
                                                ? Colors.blue[100]
                                                : Colors.grey[100],
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<CampusProvider>()
                                            .undoManualDraftPoint(
                                              widget.floorNumber,
                                            );
                                      },
                                      icon: const Icon(Icons.undo, size: 16),
                                      label: const Text(
                                        'Undo',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<CampusProvider>()
                                            .clearManualDraftFloor(
                                              widget.floorNumber,
                                            );
                                      },
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text(
                                        'Clear floor',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (_) => SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'Switch to another floor to continue drawing',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Your progress will be saved automatically',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [1, 2, 3, 4].map((
                                                    f,
                                                  ) {
                                                    final points = provider
                                                        .draftPointsForFloor(f);
                                                    return OutlinedButton(
                                                      onPressed:
                                                          f ==
                                                              widget.floorNumber
                                                          ? null
                                                          : () {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              Navigator.of(
                                                                context,
                                                              ).push(
                                                                MaterialPageRoute(
                                                                  builder: (_) => FloorMapScreen(
                                                                    floorNumber:
                                                                        f,
                                                                    floorTitle:
                                                                        f == 1
                                                                        ? 'Ground Floor'
                                                                        : f == 2
                                                                        ? '2nd Floor: Main Building'
                                                                        : f == 3
                                                                        ? '3rd Floor'
                                                                        : '4th Floor',
                                                                    imagePath:
                                                                        f == 1
                                                                        ? 'assets/images/1ST FLOOR.jpg'
                                                                        : f == 2
                                                                        ? 'assets/images/2ND FLOOR.jpg'
                                                                        : f == 3
                                                                        ? 'assets/images/3RD FLOOR.jpg'
                                                                        : 'assets/images/4TH FLOOR.jpg',
                                                                    initialStartRoomId:
                                                                        _startRoomId,
                                                                    initialDestinationRoomId:
                                                                        _destinationRoomId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                      style: OutlinedButton.styleFrom(
                                                        backgroundColor:
                                                            f ==
                                                                widget
                                                                    .floorNumber
                                                            ? Colors.grey[300]
                                                            : points.isNotEmpty
                                                            ? Colors.green[50]
                                                            : null,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text('Floor $f'),
                                                          if (points.isNotEmpty)
                                                            Text(
                                                              '${points.length} pts',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .green,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.layers, size: 16),
                                      label: const Text(
                                        'Switch floor',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed:
                                          (_startRoomId != null &&
                                              _destinationRoomId != null &&
                                              provider.hasDraft)
                                          ? () async {
                                              final provider = context
                                                  .read<CampusProvider>();
                                              await provider.saveManualDraft();
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Manual route saved! Each floor will use its custom path.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              setState(() {
                                                _editMode = false;
                                              });
                                              await _recomputeRoute();
                                              _pathAnimationController.forward(
                                                from: 0.0,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.save, size: 16),
                                      label: const Text(
                                        'Save manual route',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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
                          onPressed: () =>
                              _selectStartRoom(context, provider.rooms),
                          icon: const Icon(Icons.place),
                          label: Text(
                            _startRoomId == null
                                ? 'Select Start'
                                : 'Start: ${provider.roomById(_startRoomId!)?.name ?? _startRoomId!}',
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
                              : () => _selectDestinationRoom(
                                  context,
                                  provider.rooms,
                                ),
                          icon: const Icon(Icons.flag),
                          label: Text(
                            _destinationRoomId == null
                                ? 'Select Destination'
                                : 'Dest: ${provider.roomById(_destinationRoomId!)?.name ?? _destinationRoomId!}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_routeInstructions.isNotEmpty) ...[
                          const Text(
                            'Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._routeInstructions.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.directions_walk, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(s)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],
                        if (_routeByFloor.keys.any(
                          (f) => f != widget.floorNumber,
                        )) ...[
                          const Text(
                            'Other floors in this route',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._routeByFloor.keys
                              .where((f) => f != widget.floorNumber)
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FloorMapScreen(
                                            floorNumber: f,
                                            floorTitle: f == 1
                                                ? 'Ground Floor'
                                                : f == 2
                                                ? '2nd Floor: Main Building'
                                                : f == 3
                                                ? '3rd Floor'
                                                : '4th Floor',
                                            imagePath: f == 1
                                                ? 'assets/images/1ST FLOOR.jpg'
                                                : f == 2
                                                ? 'assets/images/2ND FLOOR.jpg'
                                                : f == 3
                                                ? 'assets/images/3RD FLOOR.jpg'
                                                : 'assets/images/4TH FLOOR.jpg',
                                            initialStartRoomId: _startRoomId,
                                            initialDestinationRoomId:
                                                _destinationRoomId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.stairs),
                                    label: Text('Open Floor $f'),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 8),
                        ],
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
      builder: (context) => _RoomSelectionDialog(
        rooms: rooms,
        title: 'Select Start Room',
        currentFloor: widget.floorNumber,
        isStartSelection: true,
      ),
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
      builder: (context) => _RoomSelectionDialog(
        rooms: rooms,
        title: 'Select Destination Room',
        currentFloor: widget.floorNumber,
        isStartSelection: false,
      ),
    );
    if (selected != null) {
      setState(() {
        _destinationRoomId = selected;
      });
      context.read<CampusProvider>().selectRoom(selected);

      // Trigger path animation
      await _recomputeRoute();
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
  final int currentFloor;
  final bool isStartSelection;

  const _RoomSelectionDialog({
    required this.rooms,
    required this.title,
    required this.currentFloor,
    required this.isStartSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out waypoints - only show actual rooms to users
    final selectableRooms = rooms.where((r) => r.type != 'waypoint').toList();

    if (isStartSelection) {
      // For start selection: only show current floor rooms, disable others
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: selectableRooms.length,
            itemBuilder: (context, index) {
              final room = selectableRooms[index];
              final isCurrentFloor = room.floor == currentFloor;
              
              return ListTile(
                enabled: isCurrentFloor,
                leading: CircleAvatar(
                  backgroundColor: isCurrentFloor ? null : Colors.grey[300],
                  child: Text(
                    room.name.replaceAll(RegExp(r'[^0-9]'), ''),
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentFloor ? null : Colors.grey[600],
                    ),
                  ),
                ),
                title: Text(
                  room.name,
                  style: TextStyle(
                    color: isCurrentFloor ? null : Colors.grey[400],
                  ),
                ),
                subtitle: Text(
                  isCurrentFloor ? room.type : '${room.type} (Floor ${room.floor})',
                  style: TextStyle(
                    color: isCurrentFloor ? null : Colors.grey[400],
                  ),
                ),
                onTap: isCurrentFloor
                    ? () {
                        Navigator.pop(context, room.id);
                      }
                    : null,
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
    } else {
      // For destination selection: group by floor with labels
      // Sort rooms by floor first
      final roomsByFloor = <int, List>{};
      for (final room in selectableRooms) {
        if (room.floor != null) {
          roomsByFloor.putIfAbsent(room.floor, () => []).add(room);
        }
      }

      // Sort floors
      final sortedFloors = roomsByFloor.keys.toList()..sort();

      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: sortedFloors.fold<int>(
              0,
              (sum, floor) => sum + 1 + (roomsByFloor[floor]?.length ?? 0),
            ),
            itemBuilder: (context, index) {
              int currentIndex = 0;
              
              for (final floor in sortedFloors) {
                // Floor header
                if (index == currentIndex) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: Colors.grey[200],
                    child: Text(
                      _getFloorLabel(floor),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                currentIndex++;

                // Rooms for this floor
                final floorRooms = roomsByFloor[floor]!;
                if (index >= currentIndex && index < currentIndex + floorRooms.length) {
                  final roomIndex = index - currentIndex;
                  final room = floorRooms[roomIndex];
                  
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
                }
                currentIndex += floorRooms.length;
              }

              return const SizedBox.shrink();
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

  String _getFloorLabel(int floor) {
    switch (floor) {
      case 1:
        return '1st Floor - Ground Floor';
      case 2:
        return '2nd Floor - Main Building';
      case 3:
        return '3rd Floor';
      case 4:
        return '4th Floor';
      default:
        return 'Floor $floor';
    }
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
