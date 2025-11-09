import 'package:flutter/material.dart';

class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigate CCA Campus'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Select a map to navigate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          _buildMapCard(
            context: context,
            title: 'Ground Floor',
            subtitle: 'First floor layout and rooms',
            imagePath: 'assets/images/1ST FLOOR.jpg',
            routeName: '/floor1',
            floor: 1,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            title: '2nd Floor: Main Building',
            subtitle: 'Second floor layout and rooms',
            imagePath: 'assets/images/2ND FLOOR.jpg',
            routeName: '/floor2',
            floor: 2,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            title: '3rd Floor',
            subtitle: 'Third floor layout and rooms',
            imagePath: 'assets/images/3RD FLOOR.jpg',
            routeName: '/floor3',
            floor: 3,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            title: '4th Floor',
            subtitle: 'Fourth floor layout and rooms',
            imagePath: 'assets/images/4TH FLOOR.jpg',
            routeName: '/floor4',
            floor: 4,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            title: 'CCA Campus Site Plan',
            subtitle: 'Complete campus overview',
            imagePath: 'assets/images/SITE-PLAN-CCA-Model-1.png',
            routeName: '/map2d',
            floor: null,
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required String routeName,
    required int? floor,
  }) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map preview image
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.map, size: 64, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                // Overlay gradient for better button visibility
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // View button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, routeName);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('VIEW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
