import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ScrollController _sc = ScrollController();
  double _progress = 0.0;

  static const String aboutText = """
The study introduces eMap, a mobile-based 2D mapping application designed to assist students in locating ICSLIS (Institute of Computing Studies, Library, and Information Science) instructors within the City College of Angeles. In a typical college environment, students often experience difficulty finding where their instructors are located or knowing their consultation hours, especially when schedules change frequently. eMap addresses this issue by providing a user-friendly interface that displays updated instructor schedules along with their assigned rooms in a visual, interactive format.

The system integrates location mapping and scheduling features, allowing students to search for instructors by name, subject, or time availability. The application's 2D digital map highlights specific rooms or locations where instructors are present, using color indicators and real-time updates to show availability status. This not only helps students save time but also minimizes disruptions caused by miscommunication or unclear schedules. Administrators can easily manage schedule data through a secure backend system, ensuring accuracy and consistency of the information displayed on the app.

Overall, eMap aims to enhance the student experience by providing a modern and efficient solution to instructor accessibility within ICSLIS. By combining mobile technology with real-time data visualization, the application promotes better communication between students and instructors, improves academic coordination, and supports a more organized school environment. This study focuses on the system’s design, development, and implementation to demonstrate its potential impact in a small college setting like CCA.
""";

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
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
        title: const Text('About eMap'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress == 0
                ? null
                : _progress, // indeterminate at top, then fills
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with logo + headings
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      'assets/images/CCA_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.school, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-MAP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '2D Location Mapping & Scheduling • ICSLIS, City College of Angeles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content with scroll indicators
          Expanded(
            child: Scrollbar(
              controller: _sc,
              interactive: true,
              thickness: 6,
              radius: const Radius.circular(12),
              child: SingleChildScrollView(
                controller: _sc,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section heading
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Body paragraphs
                    ...paragraphs.expand(
                      (p) => [
                        Text(
                          p,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(height: 1.45, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                    const SizedBox(height: 8),
                    // (Optional) subtle divider before Exit
                    const Divider(height: 24),
                    const SizedBox(height: 8),

                    // Exit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Exit'),
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
