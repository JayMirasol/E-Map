import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/campus_provider.dart';
import 'login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static void navigateTo(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final p = context.watch<CampusProvider>();
        final fmt = DateFormat('EEE h:mm a');

        final sorted = [...p.schedules]
          ..sort((a, b) {
            final d = _dayOrder(a.day).compareTo(_dayOrder(b.day));
            if (d != 0) return d;
            return a.start.compareTo(b.start);
          });

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
              ),
            ),
            title: const Text(
              'Admin — Schedules',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'Add Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => _openScheduleForm(context),
            ),
          ),
          body: sorted.isEmpty
              ? const Center(
                  child: Text('No schedules yet. Tap "Add Schedule".'),
                )
              : ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = sorted[i];
                    final room = p.roomById(s.roomId);
                    final roomName = room?.name ?? s.roomId;
                    return Dismissible(
                      key: ValueKey(s.id),
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete schedule?'),
                                content: Text(
                                  '${s.subject} by ${s.instructor}\n$roomName • ${s.day} ${fmt.format(s.start)}–${fmt.format(s.end)}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) => p.deleteSchedule(s.id),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[100]!, Colors.blue[50]!],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                          ),
                          title: Text(
                            '${s.instructor} — ${s.subject}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$roomName • ${s.day} ${fmt.format(s.start)}–${fmt.format(s.end)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.edit_rounded,
                                color: Colors.blue[700],
                              ),
                              onPressed: () =>
                                  _openScheduleForm(context, existing: s),
                              tooltip: 'Edit',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  static int _dayOrder(String d) {
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

Future<void> _openScheduleForm(
  BuildContext context, {
  Schedule? existing,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ScheduleForm(existing: existing),
  );
}

class _ScheduleForm extends StatefulWidget {
  final Schedule? existing;
  const _ScheduleForm({required this.existing});

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _instructor = TextEditingController();
  final _subject = TextEditingController();
  String? _roomId;
  String _day = 'Mon';
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 30);
  final List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s != null) {
      _instructor.text = s.instructor;
      _subject.text = s.subject;
      _roomId = s.roomId;
      _day = s.day;
      _start = TimeOfDay(hour: s.start.hour, minute: s.start.minute);
      _end = TimeOfDay(hour: s.end.hour, minute: s.end.minute);
      _schedules.add({
        'day': _day,
        'start': _start,
        'end': _end,
        'roomId': _roomId,
      });
    }
  }

  @override
  void dispose() {
    _instructor.dispose();
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampusProvider>();
    final rooms = p.rooms;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(widget.existing == null ? Icons.add : Icons.edit),
                  const SizedBox(width: 8),
                  Text(
                    widget.existing == null ? 'Add Schedule' : 'Edit Schedule',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _instructor,
                decoration: const InputDecoration(
                  labelText: 'Instructor',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue:
                    _roomId ?? (rooms.isNotEmpty ? rooms.first.id : null),
                items: rooms
                    .map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _roomId = v),
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _day,
                items: CampusProvider.days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _day = v ?? _day),
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text('Start: ${_fmt(_start)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text('End: ${_fmt(_end)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _end,
                        );
                        if (t != null) setState(() => _end = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add multiple schedules section
              const SizedBox(height: 16),
              const Text(
                'Schedules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _schedules.length,
                itemBuilder: (_, index) {
                  final schedule = _schedules[index];
                  return ListTile(
                    title: Text('${schedule['day']}'),
                    subtitle: Text(
                      'Start: ${_fmt(schedule['start'])}, End: ${_fmt(schedule['end'])}, Room: ${schedule['roomId']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          setState(() => _schedules.removeAt(index)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Schedule'),
                onPressed: () {
                  if (_roomId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a room.')),
                    );
                    return;
                  }
                  setState(() {
                    _schedules.add({
                      'day': _day,
                      'start': _start,
                      'end': _end,
                      'roomId': _roomId,
                    });
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.existing != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () async {
                          final confirmed =
                              await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete schedule?'),
                                  content: const Text(
                                    'Are you sure you want to delete this schedule?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (confirmed) {
                            final p = context.read<CampusProvider>();
                            await p.deleteSchedule(widget.existing!.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  if (widget.existing != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Schedule'),
                      onPressed: () {
                        if (_roomId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a room.'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _schedules.add({
                            'day': _day,
                            'start': _start,
                            'end': _end,
                            'roomId': _roomId,
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Save button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(widget.existing == null ? 'Save' : 'Update'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (_schedules.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one schedule.'),
                        ),
                      );
                      return;
                    }

                    final p = context.read<CampusProvider>();
                    for (final schedule in _schedules) {
                      final startDt = DateTime(
                        2025,
                        1,
                        1,
                        schedule['start'].hour,
                        schedule['start'].minute,
                      );
                      final endDt = DateTime(
                        2025,
                        1,
                        1,
                        schedule['end'].hour,
                        schedule['end'].minute,
                      );
                      if (!startDt.isBefore(endDt)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Start time must be before end time.',
                            ),
                          ),
                        );
                        return;
                      }

                      final newSched = Schedule(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        instructor: _instructor.text.trim(),
                        subject: _subject.text.trim(),
                        roomId: schedule['roomId'],
                        start: startDt,
                        end: endDt,
                        day: schedule['day'],
                      );
                      await p.addSchedule(newSched);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(TimeOfDay t) {
    final dt = DateTime(0, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }
}
