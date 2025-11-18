import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _sc = ScrollController();
  double _progress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String aboutText = """
The study introduces eMap, a mobile-based 2D mapping application designed to assist students in locating ICSLIS (Institute of Computing Studies, Library, and Information Science) instructors within the City College of Angeles. In a typical college environment, students often experience difficulty finding where their instructors are located or knowing their consultation hours, especially when schedules change frequently. eMap addresses this issue by providing a user-friendly interface that displays updated instructor schedules along with their assigned rooms in a visual, interactive format.

The system integrates location mapping and scheduling features, allowing students to search for instructors by name, subject, or time availability. The application's 2D digital map highlights specific rooms or locations where instructors are present, using color indicators and real-time updates to show availability status. This not only helps students save time but also minimizes disruptions caused by miscommunication or unclear schedules. Administrators can easily manage schedule data through a secure backend system, ensuring accuracy and consistency of the information displayed on the app.

Overall, eMap aims to enhance the student experience by providing a modern and efficient solution to instructor accessibility within ICSLIS. By combining mobile technology with real-time data visualization, the application promotes better communication between students and instructors, improves academic coordination, and supports a more organized school environment. This study focuses on the system’s design, development, and implementation to demonstrate its potential impact in a small college setting like CCA.
""";

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
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
    _sc.removeListener(_onScroll);
    _sc.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_sc.hasClients) return;
    final max = _sc.position.maxScrollExtent;
    final pixels = _sc.position.pixels;
    final p = (max <= 0) ? 0.0 : (pixels / max).clamp(0.0, 1.0);
    setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = aboutText.trim().split('\n\n');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
          ),
        ),
        title: const Text(
          'About eMap',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress == 0 ? null : _progress,
            minHeight: 3,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with logo + headings
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!,
                    Colors.blue[100]!,
                    Colors.blue[200]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo with shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: Colors.white,
                        child: Image.asset(
                          'assets/images/CCA_logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.school_rounded,
                            size: 40,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.blue[900]!, Colors.blue[600]!],
                          ).createShader(bounds),
                          child: const Text(
                            'E-MAP',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2D Location Mapping & Scheduling',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ICSLIS, City College of Angeles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content with scroll indicators
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[50]!, Colors.white],
                  ),
                ),
                child: Scrollbar(
                  controller: _sc,
                  interactive: true,
                  thickness: 6,
                  radius: const Radius.circular(12),
                  child: SingleChildScrollView(
                    controller: _sc,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section heading with accent
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[700]!,
                                    Colors.blue[400]!,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue[900],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Body paragraphs in card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                paragraphs
                                    .expand(
                                      (p) => [
                                        Text(
                                          p,
                                          textAlign: TextAlign.justify,
                                          style: TextStyle(
                                            height: 1.6,
                                            fontSize: 15,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                    .toList()
                                  ..removeLast(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Exit button with gradient
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[700]!, Colors.blue[500]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                            ),
                            label: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Footer
                        Center(
                          child: Text(
                            '© 2025 EMAP. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
