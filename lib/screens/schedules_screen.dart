// lib/screens/schedules_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../core/routes.dart';
import '../models/schedule.dart';
import 'floor_map_screen.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final TextEditingController _searchCtr = TextEditingController();
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  bool _showFilters = true;

  // init future so FutureBuilder doesn't restart repeatedly
  Future<void>? _initFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFuture ??= _loadAndPrecache(context);
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  /// 1) load provider data
  /// 2) precache all instructor images referenced in provider.instructorPhotos
  Future<void> _loadAndPrecache(BuildContext ctx) async {
    final provider = ctx.read<CampusProvider>();
    await provider.load();

    // collect distinct photo URLs that look like assets or http
    final urls = provider.instructorPhotos.values
        .toSet()
        .whereType<String>()
        .toList();

    for (final url in urls) {
      try {
        if (url.startsWith('assets/')) {
          // Attempt to load asset bytes; if successful, precache a MemoryImage
          final bd = await rootBundle.load(url);
          final bytes = bd.buffer.asUint8List();
          if (bytes.isNotEmpty) {
            await precacheImage(MemoryImage(bytes), ctx);
            if (kDebugMode) debugPrint('Precached asset image: $url');
          } else {
            if (kDebugMode) debugPrint('Asset had empty bytes: $url');
          }
        } else if (url.startsWith('http')) {
          final prov = NetworkImage(url);
          await precacheImage(prov, ctx);
          if (kDebugMode) debugPrint('Precached network image: $url');
        } else {
          // fallback: try to load as asset path anyway
          final bd = await rootBundle.load(url);
          final bytes = bd.buffer.asUint8List();
          if (bytes.isNotEmpty) await precacheImage(MemoryImage(bytes), ctx);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Precache failed for $url => $e');
        // keep going — fallback to initials will be used for this instructor
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (_, snapshot) {
        // while still loading provider & precache show a small progress
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Instructor Schedules')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final provider = context.watch<CampusProvider>();
        final fmt = DateFormat('h:mm a');

        // 1) Apply filters to schedules
        final filtered = _applyFilters(provider.schedules);

        // Build unique instructor list for icons (preserve sort by name)
        final instructors =
            provider.schedules.map((s) => s.instructor).toSet().toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Instructor Schedules',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[700]!, Colors.green[500]!],
                ),
              ),
            ),
            elevation: 0,
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
              // Professor icons row (flexible to avoid overflow)
              SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: SizedBox(
                    height: 100,
                    child: instructors.isEmpty
                        ? const Center(child: Text('No instructors available.'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: instructors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              final name = instructors[i];
                              return _buildInstructorTile(
                                context,
                                name,
                                provider,
                              );
                            },
                          ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Main schedule list grouped by day
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No schedules match your filters.'),
                      )
                    : ListView(
                        // Sort by canonical day order using CampusProvider.days
                        children: CampusProvider.days.map((day) {
                          final daySchedules =
                              filtered.where((s) => s.day == day).toList()
                                ..sort((a, b) => a.start.compareTo(b.start));
                          if (daySchedules.isEmpty) return const SizedBox();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...daySchedules.map((s) {
                                final room = provider.roomById(s.roomId);
                                final roomName = room?.name ?? s.roomId;
                                return ListTile(
                                  leading: _profCircleWithPhoto(
                                    s.instructor,
                                    provider,
                                    radius: 18,
                                  ),
                                  title: Text('${s.instructor} — ${s.subject}'),
                                  subtitle: Text(
                                    '${fmt.format(s.start)}–${fmt.format(s.end)} • Room: $roomName',
                                  ),
                                  trailing: const Icon(Icons.map),
                                  onTap: () {
                                    if (room != null) {
                                      provider.selectRoom(room.id);
                                      _navigateToFloorMap(context, room.floor);
                                    }
                                  },
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------- Instructor tile and bottom sheet ----------------

  Widget _buildInstructorTile(
    BuildContext context,
    String instructor,
    CampusProvider provider,
  ) {
    final availableNow = provider.instructorAvailableNow(instructor);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () =>
                _showInstructorSchedules(context, instructor, provider),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _profCircleWithPhoto(instructor, provider, radius: 30),
                ),
                if (availableNow)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              _shortName(instructor),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructorSchedules(
    BuildContext context,
    String instructor,
    CampusProvider provider,
  ) {
    final fmt = DateFormat('h:mm a');

    List<Schedule> schedules = provider.schedulesForInstructor(instructor);
    schedules = _applyFiltersToList(schedules);

    // Sort schedules by day order, then by start time
    schedules.sort((a, b) {
      final dayA = CampusProvider.days.indexOf(a.day);
      final dayB = CampusProvider.days.indexOf(b.day);
      if (dayA != dayB) return dayA.compareTo(dayB);
      return a.start.compareTo(b.start);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    _profCircleWithPhoto(instructor, provider, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instructor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open profile',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InstructorDetailScreen(
                              instructor: instructor,
                              provider: provider,
                            ),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_full),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (schedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No schedules available for this instructor.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: schedules.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final s = schedules[i];
                        final room = provider.roomById(s.roomId);
                        final roomName = room?.name ?? s.roomId;
                        final roomThumb = provider.roomThumbnail(s.roomId);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: roomThumb != null
                              ? SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: roomThumb.startsWith('assets/')
                                        ? Image.asset(
                                            roomThumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.meeting_room),
                                          )
                                        : Image.network(
                                            roomThumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.meeting_room),
                                          ),
                                  ),
                                )
                              : const SizedBox(
                                  width: 56,
                                  child: Icon(Icons.meeting_room),
                                ),
                          title: Text(
                            '${s.subject} (${s.day})',
                          ), // Added day here
                          subtitle: Text(
                            '${fmt.format(s.start)}–${fmt.format(s.end)}',
                          ),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.place),
                            label: Text(
                              roomName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () {
                              if (room != null) provider.selectRoom(room.id);
                              Navigator.of(ctx).pop(); // close sheet
                              if (room != null) {
                                _navigateToFloorMap(context, room.floor);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Clear all filters'),
                onPressed: () => setState(() {
                  _searchCtr.clear();
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

    final q = _searchCtr.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where(
        (s) =>
            s.instructor.toLowerCase().contains(q) ||
            s.subject.toLowerCase().contains(q),
      );
    }

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

        final overlaps = sStartMin < wEndMin && sEndMin > wStartMin;
        return overlaps;
      });
    }

    out = out.toList()
      ..sort((a, b) {
        final d = a.instructor.toLowerCase().compareTo(
          b.instructor.toLowerCase(),
        );
        if (d != 0) return d;
        return a.start.compareTo(b.start);
      });

    return out.toList();
  }

  List<Schedule> _applyFiltersToList(List<Schedule> source) {
    return _applyFilters(source);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  String _fmtToD(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  // ---------------- Helpers for professor avatars ----------------

  Widget _profCircleWithPhoto(
    String instructor,
    CampusProvider provider, {
    double radius = 18,
  }) {
    final photoUrl = provider.photoForInstructor(instructor);
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return CircleAvatar(radius: radius, child: _profInitials(instructor));
    }

    // If we already precached a MemoryImage earlier, backgroundImage will be ready.
    // Prefer MemoryImage for assets (ensures exact bytes are used) and NetworkImage for http.
    try {
      final ImageProvider prov;
      if (photoUrl.startsWith('assets/')) {
        // Attempt AssetImage first — in many cases it's fine because we precached already.
        prov = AssetImage(photoUrl);
      } else if (photoUrl.startsWith('http')) {
        prov = NetworkImage(photoUrl);
      } else {
        prov = AssetImage(photoUrl);
      }
      return CircleAvatar(
        radius: radius,
        backgroundImage: prov,
        backgroundColor: Colors.grey.shade200,
      );
    } catch (_) {
      return CircleAvatar(radius: radius, child: _profInitials(instructor));
    }
  }

  Widget _profInitials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    String initials;
    if (parts.isEmpty) {
      initials = '?';
    } else if (parts.length == 1) {
      initials = parts[0].substring(0, 1).toUpperCase();
    } else {
      initials = (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return Text(initials, style: const TextStyle(fontWeight: FontWeight.bold));
  }

  String _shortName(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return name;
  }

  void _navigateToFloorMap(BuildContext context, int? floor) {
    if (floor == null) {
      // If no floor info, show map selection screen
      Navigator.pushNamed(context, AppRoutes.mapSelection);
      return;
    }

    // Navigate to specific floor map
    switch (floor) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.floor1);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.floor2);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.floor3);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.floor4);
        break;
      default:
        // Fallback to map selection if floor is not recognized
        Navigator.pushNamed(context, AppRoutes.mapSelection);
    }
  }
}

// ---------------- A simple full-screen instructor detail page ----------------

class InstructorDetailScreen extends StatefulWidget {
  final String instructor;
  final CampusProvider provider;
  const InstructorDetailScreen({
    required this.instructor,
    required this.provider,
    super.key,
  });

  @override
  State<InstructorDetailScreen> createState() => _InstructorDetailScreenState();
}

class _InstructorDetailScreenState extends State<InstructorDetailScreen> {
  String? _selectedStartRoomId;
  String? _selectedDestinationRoomId;

  @override
  Widget build(BuildContext context) {
    final schedules = widget.provider.schedulesForInstructor(widget.instructor)
      ..sort((a, b) => a.start.compareTo(b.start));
    final fmt = DateFormat('h:mm a');
    final photoUrl = widget.provider.photoForInstructor(widget.instructor);

    final ImageProvider? imgProvider = (photoUrl != null && photoUrl.isNotEmpty)
        ? (photoUrl.startsWith('assets/')
              ? AssetImage(photoUrl)
              : NetworkImage(photoUrl))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.instructor)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imgProvider != null)
              CircleAvatar(
                radius: 44,
                backgroundImage: imgProvider,
                backgroundColor: Colors.grey.shade200,
              )
            else
              CircleAvatar(
                radius: 44,
                child: Text(widget.instructor.substring(0, 1).toUpperCase()),
              ),
            const SizedBox(height: 12),
            Text(
              widget.instructor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Navigation helper card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.navigation,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Do you want to locate this professor\'s room?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If yes, kindly choose your current location by clicking the Start button',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.room),
                            label: Text(
                              _selectedStartRoomId == null
                                  ? 'Choose Start Location'
                                  : widget.provider
                                            .roomById(_selectedStartRoomId!)
                                            ?.name ??
                                        'Start',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _selectStartLocation(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.directions),
                          label: const Text('Go'),
                          onPressed:
                              _selectedStartRoomId == null ||
                                  _selectedDestinationRoomId == null
                              ? null
                              : () => _navigateToRoomWithPath(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: schedules.isEmpty
                  ? const Center(child: Text('No schedules'))
                  : ListView.separated(
                      itemCount: schedules.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final s = schedules[i];
                        final room = widget.provider.roomById(s.roomId);
                        final roomName = room?.name ?? s.roomId;
                        final roomThumb = widget.provider.roomThumbnail(
                          s.roomId,
                        );
                        final isSelected =
                            _selectedDestinationRoomId == s.roomId;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3),
                          leading: roomThumb != null
                              ? SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: roomThumb.startsWith('assets/')
                                        ? Image.asset(
                                            roomThumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.meeting_room),
                                          )
                                        : Image.network(
                                            roomThumb,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.meeting_room),
                                          ),
                                  ),
                                )
                              : const Icon(Icons.meeting_room),
                          title: Text(s.subject),
                          subtitle: Text(
                            '${fmt.format(s.start)} – ${fmt.format(s.end)}\nRoom: $roomName',
                          ),
                          isThreeLine: true,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedDestinationRoomId = s.roomId;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectStartLocation(BuildContext context) {
    final room = widget.provider.roomById(_selectedDestinationRoomId ?? '');
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a destination room first by tapping on a schedule.',
          ),
        ),
      );
      return;
    }

    // Get all rooms from all floors, excluding waypoints, grouped by floor
    final allRooms =
        widget.provider.rooms
            .where((r) => r.type != 'waypoint' && r.floor != null)
            .toList()
          ..sort((a, b) {
            final floorCompare = a.floor!.compareTo(b.floor!);
            if (floorCompare != 0) return floorCompare;
            return a.name.compareTo(b.name);
          });

    // Group rooms by floor
    final Map<int, List<dynamic>> roomsByFloor = {};
    for (final r in allRooms) {
      roomsByFloor.putIfAbsent(r.floor!, () => []).add(r);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Your Current Location'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: allRooms.isEmpty
              ? const Text('No rooms available.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                      roomsByFloor.length + allRooms.length, // headers + rooms
                  itemBuilder: (_, index) {
                    int itemsSoFar = 0;

                    // Calculate which floor and item we're at
                    for (final floor in roomsByFloor.keys.toList()..sort()) {
                      if (index == itemsSoFar) {
                        // Floor header
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          color: Colors.green[100],
                          child: Text(
                            'Floor $floor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      itemsSoFar++;

                      final roomsOnFloor = roomsByFloor[floor]!;
                      final roomIndex = index - itemsSoFar;

                      if (roomIndex >= 0 && roomIndex < roomsOnFloor.length) {
                        final r = roomsOnFloor[roomIndex];
                        final isSelected = _selectedStartRoomId == r.id;
                        return ListTile(
                          selected: isSelected,
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(r.name),
                          subtitle: Text('Floor ${r.floor}'),
                          onTap: () {
                            setState(() {
                              _selectedStartRoomId = r.id;
                            });
                            Navigator.of(ctx).pop();
                          },
                        );
                      }

                      itemsSoFar += roomsOnFloor.length;
                    }

                    return const SizedBox.shrink();
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToRoomWithPath(BuildContext context) {
    if (_selectedStartRoomId == null || _selectedDestinationRoomId == null) {
      return;
    }

    final startRoom = widget.provider.roomById(_selectedStartRoomId!);
    final destRoom = widget.provider.roomById(_selectedDestinationRoomId!);

    if (startRoom == null || destRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find selected rooms.')),
      );
      return;
    }

    // Navigate to the floor map with both rooms selected (supports cross-floor)
    // The FloorMapScreen will handle cross-floor routing using manual routes
    Navigator.of(context).pop(); // Close instructor detail screen
    _navigateToFloorMapWithPath(
      context,
      startRoom.floor!,
      _selectedStartRoomId!,
      _selectedDestinationRoomId!,
    );
  }

  void _navigateToFloorMapWithPath(
    BuildContext context,
    int floor,
    String startRoomId,
    String destRoomId,
  ) {
    String floorTitle;
    String imagePath;

    switch (floor) {
      case 1:
        floorTitle = 'Ground Floor';
        imagePath = 'assets/images/1ST FLOOR.jpg';
        break;
      case 2:
        floorTitle = '2nd Floor: Main Building';
        imagePath = 'assets/images/2ND FLOOR.jpg';
        break;
      case 3:
        floorTitle = '3rd Floor';
        imagePath = 'assets/images/3RD FLOOR.jpg';
        break;
      case 4:
        floorTitle = '4th Floor';
        imagePath = 'assets/images/4TH FLOOR.jpg';
        break;
      default:
        Navigator.pushNamed(context, AppRoutes.mapSelection);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FloorMapScreen(
          floorNumber: floor,
          floorTitle: floorTitle,
          imagePath: imagePath,
          initialStartRoomId: startRoomId,
          initialDestinationRoomId: destRoomId,
        ),
      ),
    );
  }
}
