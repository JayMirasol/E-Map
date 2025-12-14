/// EXAMPLE: How to integrate VoiceNavigationService into Map2DScreen
///
/// This file shows the key integration points. Apply these changes to your actual map_2d_screen.dart

import 'package:flutter/material.dart';
import 'voice_navigation_service.dart';

/// STEP 1: Add voice service as a field in your State class
/// Add this near the top of _Map2DScreenState class:
///
/// ```dart
/// class _Map2DScreenState extends State<Map2DScreen> with TickerProviderStateMixin {
///   // ... existing fields ...
///
///   // Voice navigation
///   final VoiceNavigationService _voiceNav = VoiceNavigationService();
///   bool _voiceEnabled = true;
/// ```

/// STEP 2: Dispose the service
/// Add to your dispose() method:
///
/// ```dart
/// @override
/// void dispose() {
///   _voiceNav.dispose();
///   // ... rest of dispose ...
/// }
/// ```

/// STEP 3: Start voice navigation when route is computed
/// In your _computeRoute() or after route is displayed, add:
///
/// ```dart
/// void _computeRoute() {
///   // ... existing route computation code ...
///
///   setState(() {
///     _currentRoute = routePoints;
///     _pathAnimationController.forward(from: 0.0);
///   });
///
///   // NEW: Start voice navigation
///   if (_voiceEnabled && _currentRoute != null && _destinationLocationId != null) {
///     final destName = _getLocationName(_destinationLocationId!);
///     _voiceNav.announceNavigationStart(destName);
///
///     // Start turn-by-turn instructions
///     _voiceNav.startTurnByTurnNavigation(
///       _currentRoute!,
///       destName,
///       instructionInterval: const Duration(seconds: 5),
///     );
///   }
/// }
/// ```

/// STEP 4: Announce arrival at destination
/// In your _showDestinationReachedDialog() or when animation completes:
///
/// ```dart
/// void _showDestinationReachedDialog() {
///   // NEW: Announce arrival
///   if (_voiceEnabled && _destinationLocationId != null) {
///     final destName = _getLocationName(_destinationLocationId!);
///     _voiceNav.announceArrival(destName);
///   }
///
///   // ... rest of dialog code ...
/// }
/// ```

/// STEP 5: Add voice control button to UI
/// Add this widget to your build method (e.g., in a Stack or FloatingActionButton):
///
/// ```dart
/// Positioned(
///   top: 16,
///   right: 16,
///   child: FloatingActionButton(
///     mini: true,
///     backgroundColor: _voiceEnabled ? Colors.blue : Colors.grey,
///     onPressed: () {
///       setState(() {
///         _voiceEnabled = !_voiceEnabled;
///         _voiceNav.setEnabled(_voiceEnabled);
///       });
///
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Text(_voiceEnabled
///             ? 'Voice navigation enabled'
///             : 'Voice navigation disabled'
///           ),
///           duration: const Duration(seconds: 1),
///         ),
///       );
///     },
///     child: Icon(
///       _voiceEnabled ? Icons.volume_up : Icons.volume_off,
///     ),
///   ),
/// )
/// ```

/// STEP 6: Helper method to get location name
/// Add this helper method to your State class:
///
/// ```dart
/// String _getLocationName(String locationId) {
///   final location = _locations.firstWhere(
///     (loc) => loc.id == locationId,
///     orElse: () => CampusLocation(
///       id: locationId,
///       name: 'destination',
///       type: '',
///       fx: 0,
///       fy: 0
///     ),
///   );
///   return location.name;
/// }
/// ```

/// COMPLETE USAGE EXAMPLE:
class VoiceNavigationExample extends StatefulWidget {
  const VoiceNavigationExample({super.key});

  @override
  State<VoiceNavigationExample> createState() => _VoiceNavigationExampleState();
}

class _VoiceNavigationExampleState extends State<VoiceNavigationExample> {
  final VoiceNavigationService _voiceNav = VoiceNavigationService();
  bool _voiceEnabled = true;

  @override
  void dispose() {
    _voiceNav.dispose();
    super.dispose();
  }

  // Simulated route for demonstration
  void _startNavigation() {
    // Example route points (replace with your actual route data)
    final routePoints = [
      const Offset(100, 100),
      const Offset(150, 100),
      const Offset(150, 200),
      const Offset(250, 200),
      const Offset(250, 300),
    ];

    _voiceNav.announceNavigationStart("Main Building");
    _voiceNav.startTurnByTurnNavigation(routePoints, "Main Building");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Navigation Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startNavigation,
              child: const Text('Start Navigation'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _voiceEnabled = !_voiceEnabled;
                  _voiceNav.setEnabled(_voiceEnabled);
                });
              },
              child: Text(_voiceEnabled ? 'Disable Voice' : 'Enable Voice'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _voiceEnabled ? Colors.blue : Colors.grey,
        onPressed: () {
          setState(() {
            _voiceEnabled = !_voiceEnabled;
            _voiceNav.setEnabled(_voiceEnabled);
          });
        },
        child: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
      ),
    );
  }
}
