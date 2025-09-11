import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_details_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (context, snap) {
        final provider = context.watch<CampusProvider>();
        final rooms = provider.rooms;

        final center = rooms.isNotEmpty
            ? LatLng(rooms.first.lat, rooms.first.lng)
            : const LatLng(15.14715, 120.58745);

        // If a room is selected, center & zoom to it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final id = provider.selectedRoomId;
          if (id != null) {
            final r = provider.roomById(id);
            if (r != null) {
              _mapController.move(LatLng(r.lat, r.lng), 19); // zoom close
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Campus Map'),
            actions: [
              IconButton(
                tooltip: 'Clear Highlight',
                icon: const Icon(Icons.layers_clear),
                onPressed: () => provider.selectRoom(null),
              ),
            ],
          ),
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 18),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: rooms.map((r) {
                  final selected = (provider.selectedRoomId == r.id);
                  final occupied = provider.isRoomOccupiedNow(r.id);

                  final color = selected
                      ? Colors
                            .red // highlight selected
                      : (occupied ? Colors.orange : Colors.blue);

                  return Marker(
                    point: LatLng(r.lat, r.lng),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        provider.selectRoom(r.id);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.45,
                            minChildSize: 0.3,
                            maxChildSize: 0.85,
                            expand: false,
                            builder: (ctx, scrollController) {
                              // We pass the room; the sheet itself manages days and list
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  child: RoomDetailsSheet(room: r),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: Tooltip(
                        message: '${r.name} (${r.type})',
                        child: Icon(Icons.location_on, size: 40, color: color),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
