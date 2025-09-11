import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomSearchDelegate extends SearchDelegate<Room?> {
  final List<Room> source;
  RoomSearchDelegate({required this.source})
    : super(searchFieldLabel: 'Search rooms on this floor');

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final list = q.isEmpty
        ? source
        : source
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    r.id.toLowerCase().contains(q) ||
                    r.type.toLowerCase().contains(q),
              )
              .toList();

    if (list.isEmpty) {
      return const Center(child: Text('No matching rooms on this floor.'));
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = list[i];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(r.name),
          subtitle: Text(r.type.toUpperCase()),
          onTap: () => close(context, r), //
        );
      },
    );
  }
}
