import 'package:flutter/material.dart';
import '../widgets/tutorial_video_player.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  int _selectedSection = 0;

  final List<ManualSection> _sections = [
    ManualSection(
      title: 'Welcome to E-MAP',
      icon: Icons.waving_hand_rounded,
      content: [
        ManualItem(
          title: 'Explore E-MAP 👋',
          description:
              'E-MAP (2D Location Map) is your smart campus navigation companion for City College of Angeles. Navigate the campus hands-free with our new Voice Assistant feature! Find rooms, locate faculty offices, view schedules, and get turn-by-turn voice guidance.',
          icon: Icons.celebration_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Main Features',
      icon: Icons.star_rounded,
      content: [
        ManualItem(
          title: 'Interactive Campus Map 🏫',
          description:
              'View the entire CCA campus in 2D. See all three buildings: Main, NGO, and PAGCOR. Tap any building to navigate inside with multi-floor support.',
          icon: Icons.map_rounded,
        ),
        ManualItem(
          title: 'Voice Assistant Navigation 🎤',
          description:
              'NEW! Navigate hands-free using voice commands. Just tap the microphone and say "From Room 101 to Room 205" - the assistant will guide you with turn-by-turn instructions!',
          icon: Icons.mic_rounded,
        ),
        ManualItem(
          title: 'Indoor Floor Plans 🏢',
          description:
              'Navigate inside buildings with detailed floor plans. Color-coded markers show available rooms (green), occupied rooms (orange), and your destinations (red).',
          icon: Icons.location_city_rounded,
        ),
        ManualItem(
          title: 'Instructor Schedules 📅',
          description:
              'Search by instructor name or subject. Filter by day and time. Tap any schedule to see the room on the map instantly.',
          icon: Icons.calendar_month_rounded,
        ),
        ManualItem(
          title: 'Smart Routing 🚶',
          description:
              'Automatic pathfinding between locations. Cross-building navigation. Multi-floor routes. Animated walking guide showing your progress.',
          icon: Icons.directions_walk_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Quick Video Guide',
      icon: Icons.play_circle_rounded,
      content: [
        ManualItem(
          title:
              '📹 Video Tutorial (Click fullscreen to view on a better angle)',
          description:
              'A comprehensive video guide will be available here to help you get started with E-MAP. Learn how to use manual routes, voice commands, navigate between buildings, and find your way around campus.\n\n'
              'Check back soon for more tutorial video!',
          icon: Icons.videocam_rounded,
        ),
        ManualItem(
          title: 'What You\'ll Learn',
          description:
              '• How to use manual route with AI voice assistant\n'
              '• How to use voice commands for navigation\n'
              '• Finding rooms and buildings\n'
              '• Using the interactive maps\n'
              '• Viewing instructor schedules\n'
              '• Getting turn-by-turn directions',
          icon: Icons.school_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Getting Started',
      icon: Icons.rocket_launch_rounded,
      content: [
        ManualItem(
          title: 'First Time Setup',
          description:
              '1. Grant microphone permission (for voice commands)\n'
              '2. Choose your navigation method:\n'
              '   • Manual: Tap "Select Start" and "Select Destination"\n'
              '   • Voice: Tap the microphone icon 🎤\n'
              '3. Follow the route with voice guidance',
          icon: Icons.start_rounded,
        ),
        ManualItem(
          title: 'Using Voice Commands 🎤',
          description:
              '1. Tap the microphone icon (top-right)\n'
              '2. Wait for "Listening..."\n'
              '3. Say: "From [start] to [destination]"\n'
              'Examples:\n'
              '• "From Room 101 to Room 205"\n'
              '• "Main Building to NGO Building"\n'
              '• "Computer Lab to Library"',
          icon: Icons.record_voice_over_rounded,
        ),
        ManualItem(
          title: 'Voice Command Formats',
          description:
              'The system understands multiple ways:\n'
              '• "from X to Y"\n'
              '• "navigate from X to Y"\n'
              '• "X to Y"\n'
              '• "start at X destination Y"\n\n'
              'Speak clearly and use full room names for best results!',
          icon: Icons.format_quote_rounded,
        ),
        ManualItem(
          title: 'Voice Assistant Tips 💡',
          description:
              '🔇 Quiet environment works best\n'
              '🗣️ Speak clearly and slowly\n'
              '📛 Use full names (e.g., "Room 101" not "101")\n'
              '📶 Internet connection required\n'
              '🎤 Grant microphone permission when prompted',
          icon: Icons.tips_and_updates_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Voice Assistant Guide',
      icon: Icons.voice_chat_rounded,
      content: [
        ManualItem(
          title: 'Visual Voice Prompts',
          description:
              'The app shows messages while using voice:\n\n'
              '🔴 RED: "Listening... Say your start and destination"\n'
              '🟢 GREEN: "Navigation set from [start] to [destination]"\n'
              '🟠 ORANGE: "Oops! Your voice is unclear, please repeat"\n'
              '🔴 RED: "Sorry, I could not understand"',
          icon: Icons.message_rounded,
        ),
        ManualItem(
          title: 'Troubleshooting Voice',
          description:
              'Voice not working?\n\n'
              '✓ Check microphone permission in settings\n'
              '✓ Ensure stable internet connection\n'
              '✓ Reduce background noise\n'
              '✓ Speak closer to microphone\n'
              '✓ Try speaking more slowly\n'
              '✓ Use full room names',
          icon: Icons.troubleshoot_rounded,
        ),
        ManualItem(
          title: 'Common Voice Issues',
          description:
              '• "Speech recognition not available" → Check Android version 5.0+, ensure Google app installed\n\n'
              '• "Voice is unclear" → Speak more clearly, reduce noise, try alternative format\n\n'
              '• Microphone stays red → Wait for current session to complete or restart app',
          icon: Icons.info_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Navigation Guide',
      icon: Icons.explore_rounded,
      content: [
        ManualItem(
          title: 'Finding Locations',
          description:
              'Tap "Start" from the home screen, then select "Navigate CCA Campus" for outdoor navigation or choose a building floor for indoor navigation. Search for any room, office, or laboratory by name or number.',
          icon: Icons.location_on_rounded,
        ),
        ManualItem(
          title: 'Between Buildings',
          description:
              '1. Open "Navigate CCA Campus" (2D site plan)\n'
              '2. Use voice: "From Main Building to NGO Building"\n'
              '3. Or manually select buildings\n'
              '4. Follow outdoor path to entrance\n'
              '5. App switches to indoor floor plan automatically',
          icon: Icons.apartment_rounded,
        ),
        ManualItem(
          title: 'Within a Floor',
          description:
              '1. Select building floor (e.g., "Main Building 1F")\n'
              '2. Use voice: "From Room 101 to Room 105"\n'
              '3. Or tap rooms to select start/destination\n'
              '4. Follow indoor path with voice guidance\n'
              '5. Animated person shows your progress',
          icon: Icons.stairs_rounded,
        ),
        ManualItem(
          title: 'Finding Instructor Offices',
          description:
              '1. Go to "Schedules" from home screen\n'
              '2. Search for instructor\'s name\n'
              '3. Tap their schedule entry\n'
              '4. Map opens with room highlighted\n'
              '5. Tap "Navigate Here" for directions',
          icon: Icons.person_pin_circle_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Features Guide',
      icon: Icons.menu_book_rounded,
      content: [
        ManualItem(
          title: 'Room Finder',
          description:
              'Access the complete list of rooms organized by building and floor. Use the search bar to quickly find specific rooms or filter by type (classroom, lab, office).',
          icon: Icons.meeting_room_rounded,
        ),
        ManualItem(
          title: 'Faculty Directory',
          description:
              'Browse faculty members with their photos, office locations, and consultation schedules. Tap on any faculty member to see their office on the map.',
          icon: Icons.people_rounded,
        ),
        ManualItem(
          title: 'Schedules',
          description:
              'View class schedules by room, instructor, or time slot. Find out which rooms are currently available or see when specific courses are held.',
          icon: Icons.calendar_month_rounded,
        ),
        ManualItem(
          title: 'Laboratories',
          description:
              'Discover all computer labs and specialized laboratories. See their locations, available equipment, and operating hours.',
          icon: Icons.computer_rounded,
        ),
        ManualItem(
          title: 'Color-Coded Markers',
          description:
              '🟢 GREEN - Available room\n'
              '🟠 ORANGE - Currently occupied\n'
              '🔴 RED - Your selected destination\n'
              '🟣 PURPLE - Currently viewing details\n\n'
              'Markers help you quickly identify room status!',
          icon: Icons.palette_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'Tips & Tricks',
      icon: Icons.lightbulb_rounded,
      content: [
        ManualItem(
          title: 'Quick Search',
          description:
              'Use the search feature on the home screen to instantly jump to any location without browsing through menus. Just type the room number or name.',
          icon: Icons.search_rounded,
        ),
        ManualItem(
          title: 'Favorites',
          description:
              'Mark frequently visited locations as favorites for quick access. Your favorites appear at the top of the location list.',
          icon: Icons.favorite_rounded,
        ),
        ManualItem(
          title: 'Offline Mode',
          description:
              'All maps and data are stored locally, so E-MAP works without an internet connection. Perfect for navigating around campus anytime.',
          icon: Icons.wifi_off_rounded,
        ),
        ManualItem(
          title: 'Map Gestures',
          description:
              '• Pinch to zoom in/out\n• Drag to pan around\n• Double-tap to zoom in\n• Two-finger tap to zoom out\n• Tap markers for details',
          icon: Icons.touch_app_rounded,
        ),
      ],
    ),
    ManualSection(
      title: 'FAQ',
      icon: Icons.help_rounded,
      content: [
        ManualItem(
          title: 'How accurate are the routes?',
          description:
              'Routes are based on the actual campus layout and walkable paths. Walking times are estimated assuming a normal walking pace.',
          icon: Icons.question_answer_rounded,
        ),
        ManualItem(
          title: 'Can I suggest improvements?',
          description:
              'Yes! Contact the ICSLIS IT department or use the feedback option in the Administrator section to report issues or suggest features.',
          icon: Icons.feedback_rounded,
        ),
        ManualItem(
          title: 'Is my location tracked?',
          description:
              'No. E-MAP does not track your location or collect any personal data. All navigation is done locally on your device.',
          icon: Icons.privacy_tip_rounded,
        ),
        ManualItem(
          title: 'What if I find outdated information?',
          description:
              'Room assignments and schedules are updated regularly. If you notice incorrect information, please report it to the administrator.',
          icon: Icons.update_rounded,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF66BB6A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: isSmallScreen
                    ? _buildMobileLayout()
                    : Row(
                        children: [
                          // Sidebar Navigation
                          _buildSidebar(),

                          // Content Area
                          Expanded(child: _buildContent()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.menu_book_rounded,
            color: Colors.green[700],
            size: isSmallScreen ? 24 : 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Manual',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                if (!isSmallScreen)
                  Text(
                    'Your guide to using E-MAP',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedSection == index;
          return InkWell(
            onTap: () => setState(() => _selectedSection = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[700] : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sections[index].icon,
                    color: isSelected ? Colors.white : Colors.green[700],
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sections[index].title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.green[700],
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final section = _sections[_selectedSection];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(section.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Content
          Expanded(
            child: ListView.builder(
              itemCount: section.content.length,
              itemBuilder: (context, index) {
                final item = section.content[index];

                // Special handling for video tutorial section
                if (section.title == 'Quick Video Guide' && index == 0) {
                  return Column(
                    children: [
                      // First Video - Main Tutorial (Auto-play)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                '📹 Getting Started Tutorial',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TutorialVideoPlayer(
                              videoPath: 'assets/videos/emap_tutorial.mp4',
                              autoPlay: true,
                            ),
                          ],
                        ),
                      ),
                      // Second Video - Cross-floor Navigation Guide (Manual play)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16, top: 8),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                '📹 Cross-Floor Route Navigation (Guide)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TutorialVideoPlayer(
                              videoPath: 'assets/videos/cross_floor_guide.mp4',
                              autoPlay: false,
                            ),
                          ],
                        ),
                      ),
                      // Regular content item below videos
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.green[700],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Regular content items
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: Colors.green[700],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Section selector
        Container(
          height: 76,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedSection == index;
              return InkWell(
                onTap: () => setState(() => _selectedSection = index),
                child: Container(
                  width: 76,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[700] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _sections[index].icon,
                        color: isSelected ? Colors.white : Colors.green[700],
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: Text(
                          _sections[index].title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.green[700],
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }
}

class ManualSection {
  final String title;
  final IconData icon;
  final List<ManualItem> content;

  ManualSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class ManualItem {
  final String title;
  final String description;
  final IconData icon;

  ManualItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
