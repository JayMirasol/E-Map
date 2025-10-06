import 'package:flutter/material.dart';
import '../core/routes.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background design (gradient + subtle circles)
          const _BackgroundDesign(),

          // Foreground content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo (fallback to text if asset missing)
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/images/emapLogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.school, size: 96),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'E-MAP',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2D Location Mapping & Scheduling for ICSLIS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 56),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.home),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('About'),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.about),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        'Authorized only. If not, kindly disregard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Administrator'),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.admin),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
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

class _BackgroundDesign extends StatelessWidget {
  const _BackgroundDesign();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -40, left: -30, child: _circle(140, 0.10)),
          Positioned(bottom: -50, right: -20, child: _circle(180, 0.13)),
          Positioned(top: 180, right: -50, child: _circle(120, 0.08)),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}
