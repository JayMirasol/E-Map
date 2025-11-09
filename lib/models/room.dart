class Room {
  final String id;
  final String name;
  final String type; // classroom | lab | faculty | etc.
  final double lat;
  final double lng;
  final int? floor; // 1..4 for main building, null if unknown
  final double? fx; // 0..1 fractional x on that floor's image
  final double? fy; // 0..1 fractional y on that floor's image

  // NEW: optional thumbnail image URL or asset path (e.g. "assets/rooms/r102.jpg" or a remote https:// URL)
  final String? thumbnailUrl;

  // Waypoint connections - list of room/waypoint IDs this connects to
  final List<String>? waypoints;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.floor,
    this.fx,
    this.fy,
    this.thumbnailUrl,
    this.waypoints,
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
    thumbnailUrl: j.containsKey('thumbnailUrl') && j['thumbnailUrl'] != null
        ? j['thumbnailUrl'] as String
        : null,
    waypoints: j['waypoints'] != null
        ? List<String>.from(j['waypoints'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'lat': lat,
    'lng': lng,
    'floor': floor,
    'fx': fx,
    'fy': fy,
    'thumbnailUrl': thumbnailUrl,
    'waypoints': waypoints,
  };
}
