class Schedule {
  final String id; // NEW: unique id
  final String instructor;
  final String subject;
  final String roomId;
  final DateTime start;
  final DateTime end;
  final String day; // "Mon", ...

  Schedule({
    required this.id,
    required this.instructor,
    required this.subject,
    required this.roomId,
    required this.start,
    required this.end,
    required this.day,
  });

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
    id: (j['id'] ?? '').toString().isEmpty
        ? DateTime.now().microsecondsSinceEpoch
              .toString() // fallback for legacy rows
        : j['id'].toString(),
    instructor: j['instructor'],
    subject: j['subject'],
    roomId: j['roomId'],
    start: DateTime.parse(j['start']),
    end: DateTime.parse(j['end']),
    day: j['day'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'instructor': instructor,
    'subject': subject,
    'roomId': roomId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'day': day,
  };

  Schedule copyWith({
    String? id,
    String? instructor,
    String? subject,
    String? roomId,
    DateTime? start,
    DateTime? end,
    String? day,
  }) => Schedule(
    id: id ?? this.id,
    instructor: instructor ?? this.instructor,
    subject: subject ?? this.subject,
    roomId: roomId ?? this.roomId,
    start: start ?? this.start,
    end: end ?? this.end,
    day: day ?? this.day,
  );
}
