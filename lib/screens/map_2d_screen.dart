import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../models/room.dart';
import 'floor_map_screen.dart';

// Model for campus locations
class CampusLocation {
  final String id;
  final String name;
  final String type;
  final double fx;
  final double fy;
  final String? description;

  CampusLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.fx,
    required this.fy,
    this.description,
  });

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      fx: (json['fx'] as num).toDouble(),
      fy: (json['fy'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'fx': fx,
    'fy': fy,
    if (description != null) 'description': description,
  };
}

class Map2DScreen extends StatefulWidget {
  final String? startLocationId;
  final String? destinationLocationId;
  final bool autoShowRoute;
  final String? startRoomId; // For floor navigation context
  final String? destinationRoomId; // For floor navigation context

  const Map2DScreen({
    super.key,
    this.startLocationId,
    this.destinationLocationId,
    this.autoShowRoute = false,
    this.startRoomId,
    this.destinationRoomId,
  });

  @override
  State<Map2DScreen> createState() => _Map2DScreenState();
}

class _Map2DScreenState extends State<Map2DScreen>
    with TickerProviderStateMixin {
  // Campus locations and routes
  List<CampusLocation> _locations = [];
  Map<String, List<Offset>> _routes = {};

  // Navigation state
  String? _startLocationId;
  String? _destinationLocationId;
  List<Offset>? _currentRoute;

  // Room context for floor navigation
  String? _startRoomId;
  String? _destinationRoomId;

  // Manual route editing
  bool _editMode = false;
  final List<Offset> _manualRoutePoints = [];

  // Animation state
  bool _isAnimating = false;
  bool _showControls = true;
  bool _destinationReached = false;

  // Animation controllers
  late AnimationController _pathAnimationController;
  late AnimationController _markerAnimationController;
  late AnimationController _walkingAnimationController;
  late Animation<double> _pathAnimation;
  late Animation<double> _walkingAnimation;

  @override
  void initState() {
    super.initState();

    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _pathAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Walking animation - slow and realistic (8 seconds for full path)
    _walkingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );

    _pathAnimation = CurvedAnimation(
      parent: _pathAnimationController,
      curve: Curves.easeInOut,
    );

    _walkingAnimation = CurvedAnimation(
      parent: _walkingAnimationController,
      curve: Curves.linear,
    );

    // When path drawing completes, start walking animation
    _pathAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _currentRoute != null) {
        // Small delay before person starts walking
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentRoute != null) {
            setState(() => _isAnimating = true);
            // Repeat the walking animation infinitely
            _walkingAnimationController.repeat();
          }
        });
      }
    });

    // Show destination dialog when first cycle completes, but keep animation running
    _walkingAnimationController.addListener(() {
      // Check if first loop completed (reached destination)
      if (_walkingAnimationController.value >= 0.99 && !_destinationReached) {
        if (mounted) {
          setState(() {
            _destinationReached = true;
          });
          // Wait 5 seconds to let users view the complete path animation
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              _showDestinationReachedDialog();
            }
          });
        }
      }
    });

    _loadCampusData();

    // Initialize room context from widget
    _startRoomId = widget.startRoomId;
    _destinationRoomId = widget.destinationRoomId;

    // If room IDs are provided, set up manual route mode for campus navigation
    if (_startRoomId != null && _destinationRoomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCampusManualRoute();
      });
    }
    // If auto-show route is enabled and we have start/destination, display it after loading
    else if (widget.autoShowRoute &&
        widget.startLocationId != null &&
        widget.destinationLocationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoDisplayRoute();
      });
    }
  }

  void _initializeCampusManualRoute() async {
    // Wait for campus data to load
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final provider = context.read<CampusProvider>();
    final startRoom = provider.rooms.firstWhere(
      (r) => r.id == _startRoomId,
      orElse: () => Room(id: '', name: '', type: '', lat: 0, lng: 0, floor: 0),
    );
    final destRoom = provider.rooms.firstWhere(
      (r) => r.id == _destinationRoomId,
      orElse: () => Room(id: '', name: '', type: '', lat: 0, lng: 0, floor: 0),
    );

    if (startRoom.id.isEmpty || destRoom.id.isEmpty) return;

    // Determine building IDs for campus locations
    String? startBuildingId;
    String? destBuildingId;

    final startBuilding = startRoom.building ?? '';
    final destBuilding = destRoom.building ?? '';

    if (startBuilding == 'MAIN') {
      startBuildingId = 'MAIN_BUILDING';
    } else if (startBuilding == 'NGO') {
      startBuildingId = 'NGO_BUILDING';
    } else if (startBuilding == 'PAGCOR') {
      startBuildingId = 'PAGCOR_BUILDING';
    }

    if (destBuilding == 'MAIN') {
      destBuildingId = 'MAIN_BUILDING';
    } else if (destBuilding == 'NGO') {
      destBuildingId = 'NGO_BUILDING';
    } else if (destBuilding == 'PAGCOR') {
      destBuildingId = 'PAGCOR_BUILDING';
    }

    if (startBuildingId == null || destBuildingId == null) return;

    // Check if manual route already exists
    final routeKey = '$startBuildingId->$destBuildingId';
    final existingRoute = _routes[routeKey];

    setState(() {
      _startLocationId = startBuildingId;
      _destinationLocationId = destBuildingId;

      if (existingRoute != null) {
        // Route exists, display it
        _currentRoute = existingRoute;
        _pathAnimationController.forward(from: 0.0);
      } else {
        // No route, enable manual editing
        _editMode = true;
        _manualRoutePoints.clear();
      }
    });
  }

  void _autoDisplayRoute() async {
    // Wait for campus data to load
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _startLocationId = widget.startLocationId;
      _destinationLocationId = widget.destinationLocationId;
    });

    // Trigger route computation and display
    _computeRoute();
  }

  @override
  void dispose() {
    _pathAnimationController.dispose();
    _markerAnimationController.dispose();
    _walkingAnimationController.dispose();

    // Restore all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  Offset? _getPositionAlongPath(double progress) {
    if (_currentRoute == null || _currentRoute!.length < 2) return null;

    final totalSegments = _currentRoute!.length - 1;
    final segmentProgress = progress * totalSegments;
    final currentSegment = segmentProgress.floor().clamp(0, totalSegments - 1);
    final segmentFraction = segmentProgress - currentSegment;

    if (currentSegment >= totalSegments) {
      return _currentRoute!.last;
    }

    final start = _currentRoute![currentSegment];
    final end = _currentRoute![currentSegment + 1];

    return Offset(
      start.dx + (end.dx - start.dx) * segmentFraction,
      start.dy + (end.dy - start.dy) * segmentFraction,
    );
  }

  Offset? _getDirectionAtPosition(double progress) {
    if (_currentRoute == null || _currentRoute!.length < 2) return null;

    final totalSegments = _currentRoute!.length - 1;
    final segmentProgress = progress * totalSegments;
    final currentSegment = segmentProgress.floor().clamp(0, totalSegments - 1);

    if (currentSegment >= totalSegments) {
      // At the end, use direction of last segment
      final start = _currentRoute![_currentRoute!.length - 2];
      final end = _currentRoute!.last;
      return Offset(end.dx - start.dx, end.dy - start.dy);
    }

    final start = _currentRoute![currentSegment];
    final end = _currentRoute![currentSegment + 1];

    return Offset(end.dx - start.dx, end.dy - start.dy);
  }

  Future<void> _loadCampusData() async {
    try {
      // Load campus locations
      final locationsStr = await rootBundle.loadString(
        'assets/data/campus_locations.json',
      );
      final locationsList = (jsonDecode(locationsStr) as List)
          .map((e) => CampusLocation.fromJson(e))
          .toList();

      // Load campus routes
      final routesStr = await rootBundle.loadString(
        'assets/data/campus_manual_routes.json',
      );
      final routesMap = jsonDecode(routesStr) as Map<String, dynamic>;
      final routes = <String, List<Offset>>{};

      routesMap.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final segment = value[0];
          if (segment is Map && segment['points'] is List) {
            final points = (segment['points'] as List)
                .map(
                  (p) => Offset(
                    (p['fx'] as num).toDouble(),
                    (p['fy'] as num).toDouble(),
                  ),
                )
                .toList();
            routes[key] = points;
          }
        }
      });

      setState(() {
        _locations = locationsList;
        _routes = routes;
      });
    } catch (e) {
      debugPrint('Error loading campus data: $e');
    }
  }

  void _resetSelection() {
    setState(() {
      _startLocationId = null;
      _destinationLocationId = null;
      _currentRoute = null;
      _editMode = false;
      _manualRoutePoints.clear();
      _isAnimating = false;
      _showControls = true;
      _destinationReached = false;
    });
    _pathAnimationController.reset();
    _markerAnimationController.reset();
    _walkingAnimationController.stop();
    _walkingAnimationController.reset();
  }

  void _computeRoute() {
    if (_startLocationId == null || _destinationLocationId == null) return;

    final routeKey = '$_startLocationId->$_destinationLocationId';
    final route = _routes[routeKey];

    if (route != null) {
      setState(() {
        _currentRoute = route;
        _destinationReached = false;
      });

      // Start path animation
      _pathAnimationController.forward(from: 0.0);
      _markerAnimationController.repeat(reverse: true);
    } else {
      // No route found - enable manual route mode
      setState(() {
        _editMode = true;
        _manualRoutePoints.clear();
        _currentRoute = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No route found. Manual route mode enabled.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showDestinationReachedDialog() {
    final destLocation = _locations.firstWhere(
      (loc) => loc.id == _destinationLocationId,
      orElse: () =>
          CampusLocation(id: '', name: 'Destination', type: '', fx: 0, fy: 0),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Expanded(child: Text('Destination Reached!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have arrived at your destination!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.room, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destLocation.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for using E-MAP navigation!',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('See Direction First'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              // Keep animation looping, user can watch the path repeatedly
              // Animation continues until X button is pressed
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              // Stop the animation loop
              _walkingAnimationController.stop();
              _walkingAnimationController.reset();
              // Show controls and reset view
              setState(() {
                _showControls = true;
                _destinationReached = false;
                _isAnimating = false;
              });
            },
          ),
        ],
      ),
    );
  }

  void _saveManualRoute() async {
    if (_manualRoutePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 points to create a route.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routeKey = '$_startLocationId->$_destinationLocationId';
    final reverseKey = '$_destinationLocationId->$_startLocationId';

    setState(() {
      _routes[routeKey] = List.from(_manualRoutePoints);
      _routes[reverseKey] = _manualRoutePoints.reversed.toList();
      _currentRoute = _manualRoutePoints;
      _editMode = false;
    });

    // Save to provider (will be handled by campus provider)
    final provider = context.read<CampusProvider>();
    await provider.saveCampusManualRoute(
      _startLocationId!,
      _destinationLocationId!,
      _manualRoutePoints,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Saved!'),
        content: const Text(
          'Your manual route has been saved.\n\n'
          'Would you like to copy the JSON content?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final content = await provider.getCampusRoutesContent();
              if (content != null) {
                await Clipboard.setData(ClipboardData(text: content));
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'JSON copied to clipboard!\n\n'
                      'Paste it into:\n'
                      'assets/data/campus_manual_routes.json',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    _pathAnimationController.forward(from: 0.0);
  }

  void _showFloorSwitcher() {
    if (_startRoomId == null || _destinationRoomId == null) return;

    final provider = context.read<CampusProvider>();
    final startRoom = provider.rooms.firstWhere(
      (r) => r.id == _startRoomId,
      orElse: () => Room(id: '', name: '', type: '', lat: 0, lng: 0, floor: 0),
    );
    final destRoom = provider.rooms.firstWhere(
      (r) => r.id == _destinationRoomId,
      orElse: () => Room(id: '', name: '', type: '', lat: 0, lng: 0, floor: 0),
    );

    if (startRoom.id.isEmpty || destRoom.id.isEmpty) return;
    if (startRoom.floor == null || destRoom.floor == null) return;

    // Determine which floors are needed
    final startFloor = startRoom.floor!;
    final destFloor = destRoom.floor!;
    final startBuilding = startRoom.building ?? '';
    final destBuilding = destRoom.building ?? '';

    List<int> requiredFloors = [];
    String buildingLabel = '';

    // If cross-building, show destination building floors
    if (startBuilding != destBuilding && destBuilding.isNotEmpty) {
      buildingLabel = destBuilding;
      if (destBuilding == 'NGO') {
        requiredFloors = destFloor >= 5
            ? [5, 6].where((f) => f <= destFloor).toList()
            : [5, 6].where((f) => f >= destFloor).toList();
      } else if (destBuilding == 'PAGCOR') {
        requiredFloors = destFloor >= 7
            ? List.generate(destFloor - 6, (i) => i + 7)
            : List.generate(11 - destFloor, (i) => destFloor + i);
      } else {
        // MAIN building
        requiredFloors = destFloor >= 1
            ? List.generate(destFloor, (i) => i + 1)
            : [destFloor];
      }
    } else {
      // Same building, show floors between start and destination
      buildingLabel = startBuilding;
      final minFloor = startFloor < destFloor ? startFloor : destFloor;
      final maxFloor = startFloor > destFloor ? startFloor : destFloor;
      requiredFloors = List.generate(
        maxFloor - minFloor + 1,
        (i) => minFloor + i,
      );
    }

    if (requiredFloors.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Continue to $buildingLabel Floors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: requiredFloors.length,
                  itemBuilder: (context, index) {
                    final floor = requiredFloors[index];
                    final floorName = floor == 1
                        ? 'Ground Floor'
                        : 'Floor $floor';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(floorName),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);

                        // Generate floor title and image path based on floor number
                        String floorTitle;
                        String imagePath;

                        if (floor == 1) {
                          floorTitle = 'Main Building - Ground Floor';
                          imagePath =
                              'assets/images/MAIN BUILDING/GROUND FLOOR/MAIN BUILDING GROUND FLOOR.jpg';
                        } else if (floor == 2) {
                          floorTitle = 'Main Building - 2nd Floor';
                          imagePath =
                              'assets/images/MAIN BUILDING/SECOND FLOOR/MAIN BUILDING 2ND FLOOR.jpg';
                        } else if (floor == 3) {
                          floorTitle = 'Main Building - 3rd Floor';
                          imagePath =
                              'assets/images/MAIN BUILDING/THIRD FLOOR/MAIN BUILDING 3RD FLOOR.jpg';
                        } else if (floor == 4) {
                          floorTitle = 'Main Building - 4th Floor';
                          imagePath =
                              'assets/images/MAIN BUILDING/FOURTH FLOOR/MAIN BUILDING 4TH FLOOR.jpg';
                        } else if (floor == 5) {
                          floorTitle = 'NGO Building - Ground Floor';
                          imagePath =
                              'assets/images/NGO BUILDING/GROUNDFLOOR/NGO GROUND FLOOR.jpg';
                        } else if (floor == 6) {
                          floorTitle = 'NGO Building - 2nd Floor';
                          imagePath =
                              'assets/images/NGO BUILDING/SECOND FLOOR/NGO 2ND FLOOR.jpg';
                        } else if (floor == 7) {
                          floorTitle = 'PAGCOR Building - 1st Floor';
                          imagePath =
                              'assets/images/PAGCOR BUILDING/BLDG 2 1ST FLOOR F.jpg';
                        } else if (floor == 8) {
                          floorTitle = 'PAGCOR Building - 2nd Floor';
                          imagePath =
                              'assets/images/PAGCOR BUILDING/BLDG 2 2ND FLOOR.jpg';
                        } else if (floor == 9) {
                          floorTitle = 'PAGCOR Building - 3rd Floor';
                          imagePath =
                              'assets/images/PAGCOR BUILDING/BLDG 2 3RD FLOOR F.jpg';
                        } else if (floor == 10) {
                          floorTitle = 'PAGCOR Building - 4th Floor';
                          imagePath =
                              'assets/images/PAGCOR BUILDING/BLDG 2 4TH FLOOR F.jpg';
                        } else {
                          floorTitle = 'Floor $floor';
                          imagePath = '';
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FloorMapScreen(
                              floorNumber: floor,
                              floorTitle: floorTitle,
                              imagePath: imagePath,
                              initialStartRoomId: _startRoomId,
                              initialDestinationRoomId: _destinationRoomId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (context, snap) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('2D Campus Map'),
            actions: [
              IconButton(
                tooltip: 'Reset',
                icon: const Icon(Icons.close),
                onPressed: _resetSelection,
              ),
            ],
          ),
          body: Column(
            children: [
              // Map container - fullscreen during navigation
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onLongPressStart: (details) {
                          final localPosition = details.localPosition;
                          final fx = (localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          final fy = (localPosition.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0);

                          if (_editMode) {
                            // Add point to manual route
                            setState(() {
                              _manualRoutePoints.add(Offset(fx, fy));
                            });
                          } else {
                            // Show coordinates in snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Coordinates: fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'COPY',
                                  onPressed: () {
                                    // You can add clipboard copy functionality here if needed
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            children: [
                              // Campus map image
                              Image.asset(
                                'assets/images/SITE-PLAN-CCA-Model-1.png',
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
                                          Text('Failed to load campus map'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Path polyline
                              if (_currentRoute != null &&
                                  _currentRoute!.length >= 2)
                                AnimatedBuilder(
                                  animation: _pathAnimation,
                                  builder: (context, child) {
                                    final scaledPoints = _currentRoute!
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
                                        pathPoints: scaledPoints,
                                        animationProgress: _pathAnimation.value,
                                      ),
                                    );
                                  },
                                ),

                              // Manual route points during editing
                              if (_editMode && _manualRoutePoints.isNotEmpty)
                                CustomPaint(
                                  size: Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  ),
                                  painter: PathLinePainter(
                                    pathPoints: _manualRoutePoints
                                        .map(
                                          (p) => Offset(
                                            p.dx * constraints.maxWidth,
                                            p.dy * constraints.maxHeight,
                                          ),
                                        )
                                        .toList(),
                                    animationProgress: 1.0,
                                  ),
                                ),

                              // Walking stick figure
                              if (_currentRoute != null &&
                                  _currentRoute!.length >= 2 &&
                                  !_editMode)
                                AnimatedBuilder(
                                  animation: _walkingAnimation,
                                  builder: (context, child) {
                                    final progress = _walkingAnimation.value;
                                    final position = _getPositionAlongPath(
                                      progress,
                                    );
                                    if (position == null) {
                                      return const SizedBox.shrink();
                                    }

                                    // Calculate walking direction for rotation
                                    final direction = _getDirectionAtPosition(
                                      progress,
                                    );
                                    final angle = direction != null
                                        ? atan2(direction.dy, direction.dx)
                                        : 0.0;

                                    final x =
                                        position.dx * constraints.maxWidth;
                                    final y =
                                        position.dy * constraints.maxHeight;

                                    return Positioned(
                                      left: x - 10,
                                      top: y - 15,
                                      child: Transform.rotate(
                                        angle:
                                            angle +
                                            (pi /
                                                2), // Adjust for upright position
                                        child: CustomPaint(
                                          size: const Size(20, 30),
                                          painter: StickPersonPainter(
                                            walkCycle:
                                                (progress * 8) %
                                                1.0, // Leg animation
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Location markers
                              ..._locations.map((loc) {
                                final isStart = (_startLocationId == loc.id);
                                final isDest =
                                    (_destinationLocationId == loc.id);

                                Color color;
                                IconData icon;
                                double size;

                                if (isStart) {
                                  color = Colors.green;
                                  icon = Icons.place;
                                  size = 32;
                                } else if (isDest) {
                                  color = Colors.red;
                                  icon = Icons.flag;
                                  size = 32;
                                } else {
                                  color = Colors.blue;
                                  icon = Icons.location_on;
                                  size = 24;
                                }

                                return Positioned(
                                  left:
                                      loc.fx * constraints.maxWidth -
                                      (size / 2),
                                  top: loc.fy * constraints.maxHeight - size,
                                  child: GestureDetector(
                                    onTap: () => _showLocationDetails(loc),
                                    child: AnimatedBuilder(
                                      animation: _markerAnimationController,
                                      builder: (context, child) {
                                        final pulseScale = (isStart || isDest)
                                            ? 1.0 +
                                                  (_markerAnimationController
                                                          .value *
                                                      0.15)
                                            : 1.0;

                                        return Transform.scale(
                                          scale: pulseScale,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                icon,
                                                color: color,
                                                size: size,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: color,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  loc.name,
                                                  style: TextStyle(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Control panel at bottom - hidden during navigation
              if (_showControls)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _editMode,
                                    onChanged:
                                        (_startLocationId != null &&
                                            _destinationLocationId != null)
                                        ? (v) {
                                            setState(() {
                                              _editMode = v;
                                              if (v) {
                                                _manualRoutePoints.clear();
                                                _currentRoute = null;
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (_editMode) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Long-press on the map to add points (${_manualRoutePoints.length} points)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _manualRoutePoints.isNotEmpty
                                          ? () {
                                              setState(() {
                                                _manualRoutePoints.removeLast();
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.undo, size: 16),
                                      label: const Text('Undo'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _manualRoutePoints.isNotEmpty
                                          ? () {
                                              setState(() {
                                                _manualRoutePoints.clear();
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text('Clear'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _manualRoutePoints.length >= 2
                                          ? _saveManualRoute
                                          : null,
                                      icon: const Icon(Icons.save, size: 16),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Floor switcher button when in cross-building context
                              if (_startRoomId != null &&
                                  _destinationRoomId != null) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showFloorSwitcher,
                                    icon: const Icon(Icons.stairs, size: 16),
                                    label: const Text('Switch to Floor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Start and destination buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _startLocationId != null
                                      ? Colors.green
                                      : Colors.grey[300],
                                  foregroundColor: _startLocationId != null
                                      ? Colors.white
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _selectStartLocation(),
                                icon: const Icon(Icons.place, size: 20),
                                label: Text(
                                  _startLocationId == null
                                      ? 'Start'
                                      : _getLocationName(_startLocationId!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _destinationLocationId != null
                                      ? Colors.red
                                      : Colors.grey[300],
                                  foregroundColor:
                                      _destinationLocationId != null
                                      ? Colors.white
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _startLocationId == null
                                    ? null
                                    : () => _selectDestinationLocation(),
                                icon: const Icon(Icons.flag, size: 20),
                                label: Text(
                                  _destinationLocationId == null
                                      ? 'Destination'
                                      : _getLocationName(
                                          _destinationLocationId!,
                                        ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                              _buildLegendItem(Colors.green, 'Start Point'),
                              _buildLegendItem(Colors.red, 'Destination'),
                              _buildLegendItem(Colors.blue, 'Campus Location'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getLocationName(String id) {
    final loc = _locations.firstWhere(
      (l) => l.id == id,
      orElse: () =>
          CampusLocation(id: id, name: id, type: 'unknown', fx: 0, fy: 0),
    );
    return loc.name;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _selectStartLocation() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _LocationSelectionDialog(
        locations: _locations,
        title: 'Select Start Location',
      ),
    );

    if (selected != null) {
      setState(() {
        _startLocationId = selected;
        _destinationLocationId = null;
        _currentRoute = null;
        _editMode = false;
        _manualRoutePoints.clear();
      });
      _markerAnimationController.repeat(reverse: true);
    }
  }

  void _selectDestinationLocation() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _LocationSelectionDialog(
        locations: _locations,
        title: 'Select Destination',
      ),
    );

    if (selected != null) {
      setState(() {
        _destinationLocationId = selected;
      });
      _computeRoute();
    }
  }

  void _showLocationDetails(CampusLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${location.type}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (location.description != null) ...[
              const SizedBox(height: 8),
              Text(location.description!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _startLocationId = location.id;
                        _destinationLocationId = null;
                        _currentRoute = null;
                      });
                      _markerAnimationController.repeat(reverse: true);
                    },
                    icon: const Icon(Icons.place),
                    label: const Text('Set as Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startLocationId == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            setState(() {
                              _destinationLocationId = location.id;
                            });
                            _computeRoute();
                          },
                    icon: const Icon(Icons.flag),
                    label: const Text('Set as Dest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Location selection dialog
class _LocationSelectionDialog extends StatelessWidget {
  final List<CampusLocation> locations;
  final String title;

  const _LocationSelectionDialog({
    required this.locations,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final loc = locations[index];
            return ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue),
              title: Text(loc.name),
              subtitle: Text(loc.type),
              onTap: () => Navigator.pop(context, loc.id),
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

// Path painter for drawing routes
class PathLinePainter extends CustomPainter {
  final List<Offset> pathPoints;
  final double animationProgress;

  PathLinePainter({required this.pathPoints, required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(pathPoints[0].dx, pathPoints[0].dy);

    for (int i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
    }

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(
      0,
      metric.length * animationProgress,
    );

    canvas.drawPath(animatedPath, paint);

    // Draw arrow heads along the path
    if (animationProgress > 0.1) {
      final arrowPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      for (int i = 0; i < pathPoints.length - 1; i++) {
        final start = pathPoints[i];
        final end = pathPoints[i + 1];
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final angle = atan2(dy, dx);

        final arrowSize = 6.0;
        final arrowPath = Path();
        arrowPath.moveTo(end.dx, end.dy);
        arrowPath.lineTo(
          end.dx - arrowSize * cos(angle - pi / 6),
          end.dy - arrowSize * sin(angle - pi / 6),
        );
        arrowPath.lineTo(
          end.dx - arrowSize * cos(angle + pi / 6),
          end.dy - arrowSize * sin(angle + pi / 6),
        );
        arrowPath.close();

        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(PathLinePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.pathPoints != pathPoints;
  }
}

// Stick person painter for animated walking figure
class StickPersonPainter extends CustomPainter {
  final double walkCycle;

  StickPersonPainter({required this.walkCycle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Head
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.2),
      size.width * 0.15,
      paint,
    );

    // Body
    canvas.drawLine(
      Offset(center.dx, size.height * 0.35),
      Offset(center.dx, size.height * 0.65),
      paint,
    );

    // Arms (swinging)
    final armSwing = sin(walkCycle * 2 * pi) * 0.15;

    // Left arm
    canvas.drawLine(
      Offset(center.dx, size.height * 0.45),
      Offset(center.dx - size.width * 0.2, size.height * (0.55 + armSwing)),
      paint,
    );

    // Right arm
    canvas.drawLine(
      Offset(center.dx, size.height * 0.45),
      Offset(center.dx + size.width * 0.2, size.height * (0.55 - armSwing)),
      paint,
    );

    // Legs (walking animation)
    final legSwing = sin(walkCycle * 2 * pi) * 0.2;

    // Left leg
    canvas.drawLine(
      Offset(center.dx, size.height * 0.65),
      Offset(center.dx - size.width * 0.15, size.height * (0.9 + legSwing)),
      paint,
    );

    // Right leg
    canvas.drawLine(
      Offset(center.dx, size.height * 0.65),
      Offset(center.dx + size.width * 0.15, size.height * (0.9 - legSwing)),
      paint,
    );

    // Shadow underneath
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.95),
        width: size.width * 0.5,
        height: size.height * 0.1,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(StickPersonPainter oldDelegate) {
    return oldDelegate.walkCycle != walkCycle;
  }
}
