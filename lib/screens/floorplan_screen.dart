import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_details_sheet.dart';
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
        final p = context.watch<CampusProvider>();
        final selectedId = p.selectedRoomId;
        if (selectedId != null) {
          final r = p.rooms.firstWhere(
            (x) => x.id == selectedId,
            orElse: () => p.rooms.first,
          );
          final floorIndex = (r.floor != null
              ? FloorplanScreen.floors.indexOf(r.floor!)
              : 0);
          // Only jump once per build frame:
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctrl = DefaultTabController.of(context);
            if (ctrl != null && floorIndex >= 0) ctrl.index = floorIndex;
          });
        }

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
                final roomsOnFloor = p.rooms
                    .where((r) => r.floor == f)
                    .toList();
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

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampusProvider>();
    final mapped = widget.rooms
        .where((r) => r.fx != null && r.fy != null)
        .toList();
    final unmappedCount = widget.rooms.length - mapped.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        Future<void> jumpTo(Room r) async {
          if (r.fx == null || r.fy == null) return;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final target = Offset(r.fx! * w, r.fy! * h);
          const scale = 3.0; // zoom level when jumping
          final center = Offset(w / 2, h / 2);
          final translation = center - target * scale;

          // Apply transform (scale, then translate)
          _tc.value = Matrix4.identity()
            ..translate(translation.dx, translation.dy)
            ..scale(scale);

          // Open details
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
        }

        final canvas = GestureDetector(
          onLongPressStart: (d) {
            // Calibration helper (unchanged)
            final inv = Matrix4.inverted(_tc.value);
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(d.globalPosition);
            final pos = MatrixUtils.transformPoint(inv, local);
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final fx = (pos.dx / w).clamp(0.0, 1.0);
            final fy = (pos.dy / h).clamp(0.0, 1.0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Floor ${widget.floor} fx=${fx.toStringAsFixed(3)}, fy=${fy.toStringAsFixed(3)}',
                ),
              ),
            );
          },
          child: Stack(
            children: [
              if (unmappedCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _Badge(text: '$unmappedCount unmapped'),
                ),
              InteractiveViewer(
                transformationController: _tc,
                minScale: 0.7,
                maxScale: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                    ),
                    ...mapped.map(
                      (r) => _Hotspot(
                        room: r,
                        parentSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        occupied: p.isRoomOccupiedNow(r.id),
                        onTap: () => jumpTo(r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        // Add a floating search button for this floor
        return Stack(
          children: [
            canvas,
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'search-floor-${widget.floor}',
                onPressed: () async {
                  final roomsOnThisFloor = widget
                      .rooms; // search all rooms on floor, even if not mapped yet
                  final selected = await showSearch<Room?>(
                    context: context,
                    delegate: RoomSearchDelegate(source: roomsOnThisFloor),
                  );
                  if (selected != null) {
                    // If not mapped yet, just open details (no jump possible)
                    if (selected.fx == null || selected.fy == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Room has no floor coordinates yet. Long-press to calibrate and set fx/fy in rooms.json.',
                          ),
                        ),
                      );
                      // Still open details:
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.5,
                          minChildSize: 0.3,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (ctx, sc) => SingleChildScrollView(
                            controller: sc,
                            child: RoomDetailsSheet(room: selected),
                          ),
                        ),
                      );
                    } else {
                      await jumpTo(selected);
                    }
                  }
                },
                child: const Icon(Icons.search),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Hotspot extends StatelessWidget {
  final Room room;
  final Size parentSize;
  final bool occupied;
  final VoidCallback onTap;

  const _Hotspot({
    required this.room,
    required this.parentSize,
    required this.occupied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dx = (room.fx ?? 0) * parentSize.width;
    final dy = (room.fy ?? 0) * parentSize.height;
    final color = occupied ? Colors.orange : Colors.blue;

    return Positioned(
      left: dx - 14,
      top: dy - 14,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.place, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                room.name,
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
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
