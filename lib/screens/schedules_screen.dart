import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../core/routes.dart';
import '../models/schedule.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final TextEditingController _searchCtr = TextEditingController();
  String? _selectedDay; // "Sun" | "Mon" | ... or null
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  bool _showFilters = true;

  final _days = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final provider = context.watch<CampusProvider>();
        final fmt = DateFormat('h:mm a');

        // 1) Apply filters to schedules
        final filtered = _applyFilters(provider.schedules);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Instructor Schedules'),
            actions: [
              IconButton(
                tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showFilters) _buildFilters(context),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No schedules match your filters.'),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          final room = provider.roomById(s.roomId);
                          final roomName = room?.name ?? s.roomId;

                          return ListTile(
                            leading: const Icon(Icons.schedule),
                            title: Text('${s.instructor} — ${s.subject}'),
                            subtitle: Text(
                              '${s.day} • ${fmt.format(s.start)}–${fmt.format(s.end)} • Room: $roomName',
                            ),
                            trailing: const Icon(Icons.map),
                            onTap: () {
                              if (room != null) {
                                provider.selectRoom(room.id);
                              }
                              Navigator.pushNamed(context, AppRoutes.map);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Filters UI ----------------

  Widget _buildFilters(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // Search (instructor or subject)
            TextField(
              controller: _searchCtr,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search instructor or subject',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtr.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtr.clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),

            // Day chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return FilterChip(
                      label: const Text('All Days'),
                      selected: _selectedDay == null,
                      onSelected: (_) => setState(() => _selectedDay = null),
                    );
                  }
                  final day = _days[i - 1];
                  return FilterChip(
                    label: Text(day),
                    selected: _selectedDay == day,
                    onSelected: (_) => setState(() => _selectedDay = day),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Time range pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _fromTime == null
                          ? 'From (any)'
                          : 'From ${_fmtToD(_fromTime!)}',
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _fromTime ?? const TimeOfDay(hour: 7, minute: 0),
                      );
                      if (picked != null) setState(() => _fromTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _toTime == null ? 'To (any)' : 'To ${_fmtToD(_toTime!)}',
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _toTime ?? const TimeOfDay(hour: 18, minute: 0),
                      );
                      if (picked != null) setState(() => _toTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear time',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _fromTime = null;
                    _toTime = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Clear all button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Clear all filters'),
                onPressed: () => setState(() {
                  _searchCtr.clear();
                  _selectedDay = null;
                  _fromTime = null;
                  _toTime = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Filtering logic ----------------

  List<Schedule> _applyFilters(List<Schedule> source) {
    Iterable<Schedule> out = source;

    // Search over instructor OR subject
    final q = _searchCtr.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where(
        (s) =>
            s.instructor.toLowerCase().contains(q) ||
            s.subject.toLowerCase().contains(q),
      );
    }

    // Day filter
    if (_selectedDay != null) {
      out = out.where(
        (s) => s.day.toLowerCase().startsWith(_selectedDay!.toLowerCase()),
      );
    }

    // Time window filter — match if any overlap with chosen window
    if (_fromTime != null || _toTime != null) {
      out = out.where((s) {
        final sStartToD = TimeOfDay(hour: s.start.hour, minute: s.start.minute);
        final sEndToD = TimeOfDay(hour: s.end.hour, minute: s.end.minute);

        final winStart = _fromTime ?? const TimeOfDay(hour: 0, minute: 0);
        final winEnd = _toTime ?? const TimeOfDay(hour: 23, minute: 59);

        final sStartMin = _toMinutes(sStartToD);
        final sEndMin = _toMinutes(sEndToD);
        final wStartMin = _toMinutes(winStart);
        final wEndMin = _toMinutes(winEnd);

        // overlap if schedule start < window end AND schedule end > window start
        final overlaps = sStartMin < wEndMin && sEndMin > wStartMin;
        return overlaps;
      });
    }

    // Sort by day then start time (optional)
    out = out.toList()
      ..sort((a, b) {
        final d = _dayOrder(a.day).compareTo(_dayOrder(b.day));
        if (d != 0) return d;
        return a.start.compareTo(b.start);
      });

    return out.toList();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  String _fmtToD(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  int _dayOrder(String d) {
    final norm = (d.length >= 3 ? d.substring(0, 3) : d).toLowerCase();
    switch (norm) {
      case 'sun':
        return 0;
      case 'mon':
        return 1;
      case 'tue':
        return 2;
      case 'wed':
        return 3;
      case 'thu':
        return 4;
      case 'fri':
        return 5;
      case 'sat':
        return 6;
      default:
        return 7;
    }
  }
}
