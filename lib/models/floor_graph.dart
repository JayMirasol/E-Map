import 'dart:math';

class GraphNode {
  final String id;
  final double fx; // normalized 0..1
  final double fy; // normalized 0..1
  final String? type; // "corridor", "door", etc.
  final String? room; // optional: room this door belongs to

  GraphNode({
    required this.id,
    required this.fx,
    required this.fy,
    this.type,
    this.room,
  });
}

class GraphEdge {
  final String from;
  final String to;
  final double cost;

  GraphEdge({required this.from, required this.to, required this.cost});
}

class FloorGraph {
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, String> roomToDoorNode; // roomName -> nodeId

  FloorGraph({
    required this.nodes,
    required this.edges,
    required this.roomToDoorNode,
  });

  factory FloorGraph.fromJson(Map<String, dynamic> j) {
    final cs =
        (j['metadata']?['coordinate_space'] ?? {}) as Map<String, dynamic>;
    final w = ((cs['width'] ?? 1000) as num).toDouble();
    final h = ((cs['height'] ?? 1000) as num).toDouble();

    final nodesObj = (j['nodes'] as Map<String, dynamic>);
    final nodes = <String, GraphNode>{};
    nodesObj.forEach((id, val) {
      final m = val as Map<String, dynamic>;
      final x = (m['x'] as num).toDouble();
      final y = (m['y'] as num).toDouble();
      nodes[id] = GraphNode(
        id: id,
        fx: (x / w).clamp(0.0, 1.0),
        fy: (y / h).clamp(0.0, 1.0),
        type: m['type'] as String?,
        room: m['room'] as String?,
      );
    });

    final edgesArr = (j['edges'] as List).cast<Map<String, dynamic>>();
    final edges = edgesArr.map((e) {
      final cost =
          (e['cost'] as num?)?.toDouble() ??
          _euclid(nodes[e['from']]!, nodes[e['to']]!);
      return GraphEdge(from: e['from'], to: e['to'], cost: cost);
    }).toList();

    final roomsMap =
        (j['rooms'] as Map?)?.cast<String, String>() ?? <String, String>{};

    return FloorGraph(nodes: nodes, edges: edges, roomToDoorNode: roomsMap);
  }

  static double _euclid(GraphNode a, GraphNode b) {
    final dx = a.fx - b.fx, dy = a.fy - b.fy;
    return sqrt(dx * dx + dy * dy);
  }
}
