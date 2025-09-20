import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../providers/campus_provider.dart';

class RoomDetailsSheet extends StatefulWidget {
  final Room room;
  const RoomDetailsSheet({super.key, required this.room});

  @override
  State<RoomDetailsSheet> createState() => _RoomDetailsSheetState();
}

class _RoomDetailsSheetState extends State<RoomDetailsSheet> {
  late String _day;
  final _fmt = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    final p = context.read<CampusProvider>();
    _day = p.todayAbbrev();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampusProvider>();
    final occupied = p.isRoomOccupiedNow(widget.room.id);
    final schedules = p.schedulesForRoomAndDay(widget.room.id, _day);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.meeting_room,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Chip(
                            text: widget.room.type.toUpperCase(),
                            icon: Icons.category,
                          ),
                          const SizedBox(width: 6),
                          _Chip(
                            text: occupied ? 'OCCUPIED NOW' : 'Available',
                            icon: occupied
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                            tone: occupied
                                ? ChipTone.warning
                                : ChipTone.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Day selector
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: CampusProvider.days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final d = CampusProvider.days[i];
                  final selected = d == _day;
                  return ChoiceChip(
                    label: Text(d),
                    selected: selected,
                    onSelected: (_) => setState(() => _day = d),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Schedule list (full day for this room)
            if (schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18.0),
                child: Row(
                  children: [
                    Icon(Icons.event_busy),
                    SizedBox(width: 8),
                    Expanded(child: Text('No classes scheduled for this day.')),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = schedules[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const Icon(Icons.class_),
                      title: Text('${s.subject} — ${s.instructor}'),
                      subtitle: Text(
                        '${_fmt.format(s.start)} – ${_fmt.format(s.end)}',
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

enum ChipTone { neutral, success, warning }

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  final ChipTone tone;
  const _Chip({
    required this.text,
    required this.icon,
    this.tone = ChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case ChipTone.success:
        bg = Colors.green.withOpacity(.12);
        fg = Colors.green.shade800;
        break;
      case ChipTone.warning:
        bg = Colors.orange.withOpacity(.12);
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Theme.of(context).colorScheme.secondaryContainer.withOpacity(.45);
        fg = Theme.of(context).colorScheme.onSecondaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
