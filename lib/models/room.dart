class Room {
  final String id;
  final String name;
  final String type; // classroom | lab | faculty | etc.
  final double lat;
  final double lng;
  final int? floor; // 1..4 for main building, null if unknown
  final double? fx; // 0..1 fractional x on that floor’s image
  final double? fy; // 0..1 fractional y on that floor’s image

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.floor,
    this.fx,
    this.fy,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'],
    name: j['name'],
    type: j['type'],
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    floor: j['floor'], // may be null
    fx: j['fx'] == null ? null : (j['fx'] as num).toDouble(),
    fy: j['fy'] == null ? null : (j['fy'] as num).toDouble(),
  );
}
