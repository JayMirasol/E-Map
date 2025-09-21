import 'package:collection/collection.dart';
import 'dart:math';
import '../models/floor_graph.dart';

class _PQEntry<T> implements Comparable<_PQEntry<T>> {
  final T value;
  final double priority;
  _PQEntry(this.value, this.priority);
  @override
  int compareTo(_PQEntry<T> other) => priority.compareTo(other.priority);
}

class Pathfinder {
  static List<String> aStar(FloorGraph g, String startId, String goalId) {
    if (!g.nodes.containsKey(startId) || !g.nodes.containsKey(goalId))
      return [];

    double h(String a, String b) {
      final na = g.nodes[a]!, nb = g.nodes[b]!;
      final dx = na.fx - nb.fx, dy = na.fy - nb.fy;
      return sqrt(dx * dx + dy * dy);
    }

    final adj = <String, List<Map<String, dynamic>>>{};
    for (final e in g.edges) {
      adj.putIfAbsent(e.from, () => []);
      adj.putIfAbsent(e.to, () => []);
      final w = e.cost;
      adj[e.from]!.add({"to": e.to, "w": w});
      adj[e.to]!.add({"to": e.from, "w": w});
    }

    final open = HeapPriorityQueue<_PQEntry<String>>()
      ..add(_PQEntry(startId, 0));
    final cameFrom = <String, String?>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};

    for (final id in g.nodes.keys) {
      gScore[id] = double.infinity;
      fScore[id] = double.infinity;
      cameFrom[id] = null;
    }
    gScore[startId] = 0.0;
    fScore[startId] = h(startId, goalId);

    final inOpen = <String>{startId};

    while (open.isNotEmpty) {
      final current = open.removeFirst().value;
      inOpen.remove(current);

      if (current == goalId) {
        final path = <String>[];
        var cur = goalId;
        while (cur != startId) {
          path.add(cur);
          cur = cameFrom[cur]!;
        }
        path.add(startId);
        return path.reversed.toList();
      }

      for (final e in adj[current] ?? const []) {
        final nb = e["to"] as String;
        final w = e["w"] as double;
        final tentative = gScore[current]! + w;
        if (tentative < gScore[nb]!) {
          cameFrom[nb] = current;
          gScore[nb] = tentative;
          fScore[nb] = tentative + h(nb, goalId);
          if (!inOpen.contains(nb)) {
            open.add(_PQEntry(nb, fScore[nb]!));
            inOpen.add(nb);
          }
        }
      }
    }
    return [];
  }

  static String? nearestNodeId(FloorGraph g, double fx, double fy) {
    String? best;
    var bestD = double.infinity;
    g.nodes.forEach((id, n) {
      final dx = n.fx - fx, dy = n.fy - fy;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD) {
        bestD = d2;
        best = id;
      }
    });
    return best;
  }
}
