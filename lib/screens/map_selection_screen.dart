import 'package:flutter/material.dart';
import 'floor_map_screen.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigate CCA Campus',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[800]!, Colors.green[600]!],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Enhanced Quick Demo Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green[100]!, Colors.green[50]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FloorMapScreen(
                            floorNumber: 1,
                            floorTitle: 'Ground Floor',
                            imagePath: 'assets/images/1ST FLOOR.jpg',
                            initialStartRoomId: 'BFO',
                            initialDestinationRoomId: 'MISSO',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green[700]!,
                                  Colors.green[500]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Demo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'BFO (1F) → MISSO (2F)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cross-floor navigation demo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.green[700],
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select a map to navigate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'Ground Floor - Main Building',
                subtitle: 'First floor layout and rooms',
                imagePath: 'assets/images/1ST FLOOR.jpg',
                routeName: '/floor1',
                floor: 1,
                index: 0,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: '2nd Floor - Main Building',
                subtitle: 'Second floor layout and rooms',
                imagePath: 'assets/images/2ND FLOOR.jpg',
                routeName: '/floor2',
                floor: 2,
                index: 1,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: '3rd Floor - Main Building',
                subtitle: 'Third floor layout and rooms',
                imagePath: 'assets/images/3RD FLOOR.jpg',
                routeName: '/floor3',
                floor: 3,
                index: 2,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: '4th Floor - Main Building',
                subtitle: 'Fourth floor layout and rooms',
                imagePath: 'assets/images/4TH FLOOR.jpg',
                routeName: '/floor4',
                floor: 4,
                index: 3,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'NGO Building - Ground Floor',
                subtitle: 'NGO Building ground floor rooms',
                imagePath:
                    'assets/images/NGO BUILDING/GROUNDFLOOR/NGO GROUND FLOOR.jpg',
                routeName: '/ngo-ground',
                floor: 5,
                index: 4,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'NGO Building - 2nd Floor',
                subtitle: 'NGO Building second floor rooms',
                imagePath:
                    'assets/images/NGO BUILDING/SECOND FLOOR/NGO 2ND FLOOR.jpg',
                routeName: '/ngo-2nd',
                floor: 6,
                index: 5,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'PAGCOR Building - 1st Floor',
                subtitle: 'PAGCOR Building first floor rooms',
                imagePath:
                    'assets/images/PAGCOR BUILDING/BLDG 2 1ST FLOOR F.jpg',
                routeName: '/pagcor-1st',
                floor: 7,
                index: 6,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'PAGCOR Building - 2nd Floor',
                subtitle: 'PAGCOR Building second floor rooms',
                imagePath: 'assets/images/PAGCOR BUILDING/BLDG 2 2ND FLOOR.jpg',
                routeName: '/pagcor-2nd',
                floor: 8,
                index: 7,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'PAGCOR Building - 3rd Floor',
                subtitle: 'PAGCOR Building third floor rooms',
                imagePath:
                    'assets/images/PAGCOR BUILDING/BLDG 2 3RD FLOOR F.jpg',
                routeName: '/pagcor-3rd',
                floor: 9,
                index: 8,
              ),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'PAGCOR Building - 4th Floor',
                subtitle: 'PAGCOR Building fourth floor rooms',
                imagePath:
                    'assets/images/PAGCOR BUILDING/BLDG 2 4TH FLOOR F.jpg',
                routeName: '/pagcor-4th',
                floor: 10,
                index: 9,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildMapCard(
                context: context,
                title: 'CCA Campus Site Plan',
                subtitle: 'Complete campus overview',
                imagePath: 'assets/images/SITE-PLAN-CCA-Model-1.png',
                routeName: '/map2d',
                floor: null,
                index: 10,
              ),
            ],
          ),
        ),
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
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
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
                              child: Icon(
                                Icons.map,
                                size: 64,
                                color: Colors.grey,
                              ),
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
                    // Enhanced View button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[700]!, Colors.blue[500]!],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, routeName);
                        },
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text(
                          'VIEW MAP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Enhanced card content
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.green[50]!],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
