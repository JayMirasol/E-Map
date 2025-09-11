import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const RoomTile({super.key, required this.room, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(room.name),
      subtitle: Text(room.type.toUpperCase()),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
