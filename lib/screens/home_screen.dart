import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../widgets/start_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile('Room Locator', Icons.location_pin, AppRoutes.rooms),
      _HomeTile('Schedules', Icons.schedule, AppRoutes.schedules),
      _HomeTile('Faculty Rooms', Icons.meeting_room, AppRoutes.faculty),
      _HomeTile('Laboratory Rooms', Icons.computer, AppRoutes.labs),
      _HomeTile('Floorplan', Icons.layers, AppRoutes.floorplan),
      _HomeTile('Admin', Icons.admin_panel_settings, AppRoutes.admin),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('EMAP')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text(
              '2D Location Mapping & Scheduling',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const StartButton(), // ✔ Recommendation: add a Start button like map apps (from PDF)
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: tiles.length,
              itemBuilder: (_, i) => _HomeCard(tile: tiles[i]),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile {
  final String title;
  final IconData icon;
  final String route;
  _HomeTile(this.title, this.icon, this.route);
}

class _HomeCard extends StatelessWidget {
  final _HomeTile tile;
  const _HomeCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, tile.route),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tile.icon, size: 36),
              const SizedBox(height: 8),
              Text(tile.title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
