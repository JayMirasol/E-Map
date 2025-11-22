import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/campus_provider.dart';
import '../widgets/room_tile.dart';
import '../core/routes.dart';
import 'floor_map_screen.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFloorMap(
    BuildContext context,
    room,
    CampusProvider provider,
  ) {
    if (room.floor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room has no floor information')),
      );
      return;
    }

    provider.selectRoom(room.id);

    String floorTitle;
    String imagePath;

    switch (room.floor) {
      case 1:
        floorTitle = 'Ground Floor';
        imagePath = 'assets/images/1ST FLOOR.jpg';
        break;
      case 2:
        floorTitle = '2nd Floor: Main Building';
        imagePath = 'assets/images/2ND FLOOR.jpg';
        break;
      case 3:
        floorTitle = '3rd Floor';
        imagePath = 'assets/images/3RD FLOOR.jpg';
        break;
      case 4:
        floorTitle = '4th Floor';
        imagePath = 'assets/images/4TH FLOOR.jpg';
        break;
      default:
        Navigator.pushNamed(context, AppRoutes.mapSelection);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FloorMapScreen(
          floorNumber: room.floor!,
          floorTitle: floorTitle,
          imagePath: imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CampusProvider>().load(),
      builder: (_, __) {
        final p = context.watch<CampusProvider>();
        final allRooms = p.byType('faculty');

        // Filter rooms based on search query
        final rooms = allRooms.where((room) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return room.name.toLowerCase().contains(query) ||
              room.id.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Faculty Rooms',
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
                  colors: [Colors.green[700]!, Colors.green[500]!],
                ),
              ),
            ),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search faculty rooms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green[500]!,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // Room list
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: rooms.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No faculty rooms yet'
                                : 'No rooms found matching "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: rooms.length,
                          itemBuilder: (_, i) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (i * 50)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.green[50]!, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: RoomTile(
                                  room: rooms[i],
                                  onTap: () {
                                    _navigateToFloorMap(context, rooms[i], p);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
