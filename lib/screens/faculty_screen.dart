import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_tile.dart';

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final rooms = context.watch<CampusProvider>().byType('faculty');
        return Scaffold(
          appBar: AppBar(title: const Text('Faculty Rooms')),
          body: rooms.isEmpty
              ? const Center(child: Text('No faculty rooms yet'))
              : ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => RoomTile(room: rooms[i]),
                ),
        );
      },
    );
  }
}
