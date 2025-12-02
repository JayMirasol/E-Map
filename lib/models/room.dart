class Room {
  final String id;
  final String name;
  final String type; // classroom | lab | faculty | etc.
  final double lat;
  final double lng;
  final int? floor; // 1..4 for main building, 5-6 for NGO, 7-10 for PAGCOR
  final String? building; // MAIN | NGO | PAGCOR
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
    this.building,
    this.fx,
    this.fy,
    this.thumbnailUrl,
    this.waypoints,
  });

  factory Room.fromJson(Map<String, dynamic> j) {
    // Auto-detect building from floor number if not specified
    String? building = j['building'] as String?;
    if (building == null && j['floor'] != null) {
      final floor = j['floor'] as int;
      if (floor >= 1 && floor <= 4) {
        building = 'MAIN';
      } else if (floor >= 5 && floor <= 6) {
        building = 'NGO';
      } else if (floor >= 7 && floor <= 10) {
        building = 'PAGCOR';
      }
    }

    return Room(
      id: j['id'],
      name: j['name'],
      type: j['type'],
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      floor: j['floor'], // may be null
      building: building,
      fx: j['fx'] == null ? null : (j['fx'] as num).toDouble(),
      fy: j['fy'] == null ? null : (j['fy'] as num).toDouble(),
      thumbnailUrl: j.containsKey('thumbnailUrl') && j['thumbnailUrl'] != null
          ? j['thumbnailUrl'] as String
          : null,
      waypoints: j['waypoints'] != null
          ? List<String>.from(j['waypoints'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'lat': lat,
    'lng': lng,
    'floor': floor,
    'building': building,
    'fx': fx,
    'fy': fy,
    'thumbnailUrl': thumbnailUrl,
    'waypoints': waypoints,
  };
}
