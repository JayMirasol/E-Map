import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/campus_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
          appBar: AppBar(title: const Text('Admin — Schedules')),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
            onPressed: () => _openScheduleForm(context),
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
                      child: ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text('${s.instructor} — ${s.subject}'),
                        subtitle: Text(
                          '$roomName • ${s.day} ${fmt.format(s.start)}–${fmt.format(s.end)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _openScheduleForm(context, existing: s),
                          tooltip: 'Edit',
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

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(widget.existing == null ? 'Save' : 'Update'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (_roomId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a room.')),
                      );
                      return;
                    }
                    final startDt = DateTime(
                      2025,
                      1,
                      1,
                      _start.hour,
                      _start.minute,
                    );
                    final endDt = DateTime(2025, 1, 1, _end.hour, _end.minute);
                    if (!startDt.isBefore(endDt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Start time must be before end time.'),
                        ),
                      );
                      return;
                    }

                    final p = context.read<CampusProvider>();
                    if (widget.existing == null) {
                      final newSched = Schedule(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        instructor: _instructor.text.trim(),
                        subject: _subject.text.trim(),
                        roomId: _roomId!,
                        start: startDt,
                        end: endDt,
                        day: _day,
                      );
                      await p.addSchedule(newSched);
                    } else {
                      final upd = widget.existing!.copyWith(
                        instructor: _instructor.text.trim(),
                        subject: _subject.text.trim(),
                        roomId: _roomId!,
                        start: startDt,
                        end: endDt,
                        day: _day,
                      );
                      await p.updateSchedule(upd);
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
