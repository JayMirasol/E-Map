import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_tile.dart';
import '../core/routes.dart';
import '../widgets/room_details_sheet.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final p = context.watch<CampusProvider>();
        final rooms = p.rooms;

        return Scaffold(
          appBar: AppBar(title: const Text('Rooms')),
          body: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => RoomTile(
              room: rooms[i],
              onTap: () {
                // go to map & highlight
                p.selectRoom(rooms[i].id);
                Navigator.pushNamed(context, AppRoutes.map);
              },
              // NEW: long-press to see details here
              onLongPress: () {
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
                    builder: (ctx, scrollController) => SingleChildScrollView(
                      controller: scrollController,
                      child: RoomDetailsSheet(room: rooms[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
