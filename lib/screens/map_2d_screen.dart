import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_details_sheet.dart';

class Map2DScreen extends StatefulWidget {
  const Map2DScreen({super.key});

  @override
  State<Map2DScreen> createState() => _Map2DScreenState();
}

class _Map2DScreenState extends State<Map2DScreen> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (context, snap) {
        final provider = context.watch<CampusProvider>();
        final rooms = provider.rooms;

        // Focus on selected room if any
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final id = provider.selectedRoomId;
          if (id != null) {
            final r = provider.roomById(id);
            if (r != null && r.fx != null && r.fy != null) {
              // Zoom to the selected room position
              _centerOnRoom(r.fx!, r.fy!);
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('2D Campus Map'),
            actions: [
              IconButton(
                tooltip: 'OSM Map View',
                icon: const Icon(Icons.satellite_alt),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              IconButton(
                tooltip: 'Clear Highlight',
                icon: const Icon(Icons.layers_clear),
                onPressed: () => provider.selectRoom(null),
              ),
              IconButton(
                tooltip: 'Reset Zoom',
                icon: const Icon(Icons.zoom_out_map),
                onPressed: () {
                  _transformationController.value = Matrix4.identity();
                },
              ),
            ],
          ),
          body: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(100),
            child: Stack(
              children: [
                // Campus map image
                Image.asset(
                  'assets/images/SITE-PLAN-CCA-Model-1.png',
                  fit: BoxFit.contain,
                ),
                // Room markers positioned using fx/fy coordinates
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Get the image dimensions to calculate marker positions
                    return Stack(
                      children: rooms
                          .where((r) {
                            // Only show rooms that have fx/fy coordinates
                            return r.fx != null && r.fy != null;
                          })
                          .map((r) {
                            final selected = (provider.selectedRoomId == r.id);
                            final occupied = provider.isRoomOccupiedNow(r.id);

                            final color = selected
                                ? Colors.red
                                : (occupied ? Colors.orange : Colors.blue);

                            // Use image size for positioning
                            // fx and fy are fractional coordinates (0.0 to 1.0)
                            return Positioned(
                              left: r.fx! * constraints.maxWidth - 22,
                              top: r.fy! * constraints.maxHeight - 44,
                              child: GestureDetector(
                                onTap: () {
                                  provider.selectRoom(r.id);
                                  _showRoomDetails(context, r, provider);
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      r.name.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ), // Show room number only
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _centerOnRoom(double fx, double fy) {
    // Calculate the transformation to center on the room
    // This is a simplified approach - adjust scale and translation as needed
    const scale = 2.0;
    final dx =
        -fx * scale * MediaQuery.of(context).size.width +
        MediaQuery.of(context).size.width / 2;
    final dy =
        -fy * scale * MediaQuery.of(context).size.height +
        MediaQuery.of(context).size.height / 2;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
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
}
