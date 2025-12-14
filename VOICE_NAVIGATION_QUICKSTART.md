/// QUICK START: Voice Navigation Integration
/// Copy-paste these code snippets into your files to add voice navigation
/// 
/// This file contains READY-TO-USE code snippets for quick integration

// ============================================================================
// FOR: lib/screens/map_2d_screen.dart
// ============================================================================

// 1. ADD IMPORT at top of file (around line 1-10):
import '../services/voice_navigation_service.dart';

// 2. ADD FIELDS to _Map2DScreenState class (around line 70-100):
  final VoiceNavigationService _voiceNav = VoiceNavigationService();
  bool _voiceEnabled = true;

// 3. ADD TO dispose() method (around line 260-280):
  @override
  void dispose() {
    _voiceNav.dispose(); // ADD THIS LINE
    _pathAnimationController.dispose();
    _markerAnimationController.dispose();
    _walkingAnimationController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

// 4. FIND your _computeRoute() or route display method and ADD AFTER route is set:
  // Example location: after _currentRoute = ... and before setState
  if (_voiceEnabled && _currentRoute != null && _destinationLocationId != null) {
    final dest = _locations.firstWhere(
      (loc) => loc.id == _destinationLocationId,
      orElse: () => CampusLocation(
        id: '', name: 'destination', type: '', fx: 0, fy: 0
      ),
    );
    
    _voiceNav.announceNavigationStart(dest.name);
    _voiceNav.startTurnByTurnNavigation(
      _currentRoute!,
      dest.name,
      instructionInterval: const Duration(seconds: 5),
    );
  }

// 5. FIND _showDestinationReachedDialog() and ADD at the start:
  void _showDestinationReachedDialog() {
    // ADD THIS:
    if (_voiceEnabled && _destinationLocationId != null) {
      final dest = _locations.firstWhere(
        (loc) => loc.id == _destinationLocationId,
        orElse: () => CampusLocation(
          id: '', name: 'destination', type: '', fx: 0, fy: 0
        ),
      );
      _voiceNav.announceArrival(dest.name);
    }
    
    // ... rest of your existing dialog code ...
  }

// 6. ADD VOICE BUTTON to your build() method's Stack children:
  // Find the Stack widget in your build() method and add this as a child:
  Positioned(
    top: 16,
    right: 16,
    child: FloatingActionButton(
      mini: true,
      heroTag: 'voice_campus_btn',
      backgroundColor: _voiceEnabled 
          ? const Color(0xFF1976D2) 
          : Colors.grey.shade600,
      elevation: 4,
      tooltip: _voiceEnabled ? 'Mute voice navigation' : 'Enable voice navigation',
      onPressed: () {
        setState(() {
          _voiceEnabled = !_voiceEnabled;
          _voiceNav.setEnabled(_voiceEnabled);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(_voiceEnabled 
                    ? 'Voice navigation enabled' 
                    : 'Voice navigation muted'
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _voiceEnabled ? Colors.green : Colors.grey,
          ),
        );
      },
      child: Icon(
        _voiceEnabled ? Icons.volume_up : Icons.volume_off,
        size: 20,
      ),
    ),
  ),


// ============================================================================
// FOR: lib/screens/floor_map_screen.dart
// ============================================================================

// 1. ADD IMPORT at top of file:
import '../services/voice_navigation_service.dart';

// 2. ADD FIELDS to _FloorMapScreenState class:
  final VoiceNavigationService _voiceNav = VoiceNavigationService();
  bool _voiceEnabled = true;

// 3. ADD TO dispose() method:
  @override
  void dispose() {
    _voiceNav.dispose(); // ADD THIS LINE
    _continuePromptTimer?.cancel();
    _countdownTimer?.cancel();
    _pathAnimationController.dispose();
    _markerAnimationController.dispose();
    _walkingPersonAnimationController.dispose();
    _transformationController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

// 4. FIND where you start pathfinding/navigation and ADD:
  // After route is computed and set:
  if (_voiceEnabled && _destinationRoomId != null) {
    final provider = context.read<CampusProvider>();
    final destRoom = provider.rooms.firstWhere(
      (r) => r.id == _destinationRoomId,
      orElse: () => Room(id: '', name: 'Room', type: '', lat: 0, lng: 0, floor: 0),
    );
    
    if (destRoom.id.isNotEmpty) {
      _voiceNav.announceNavigationStart(destRoom.name);
      
      // If you have route points for this floor:
      if (_routeByFloor[widget.floorNumber] != null) {
        _voiceNav.startTurnByTurnNavigation(
          _routeByFloor[widget.floorNumber]!,
          destRoom.name,
        );
      }
    }
  }

// 5. FIND floor transition logic and ADD announcement:
  // When switching floors (look for Navigator.pushReplacement or similar):
  void _switchToFloor(int nextFloor, String connectorName) {
    // ADD THIS before navigation:
    if (_voiceEnabled) {
      _voiceNav.announceFloorChange(
        widget.floorNumber,
        nextFloor,
        connectorName, // e.g., "Stairs A" or "Elevator B"
      );
    }
    
    // ... your existing floor switch code ...
  }

// 6. ADD VOICE BUTTON to build() Stack:
  // Add this to your Stack children in build():
  Positioned(
    top: 80, // Below other controls
    right: 16,
    child: FloatingActionButton(
      mini: true,
      heroTag: 'voice_floor_btn',
      backgroundColor: _voiceEnabled 
          ? const Color(0xFF1976D2) 
          : Colors.grey.shade600,
      tooltip: _voiceEnabled ? 'Mute voice' : 'Enable voice',
      onPressed: () {
        setState(() {
          _voiceEnabled = !_voiceEnabled;
          _voiceNav.setEnabled(_voiceEnabled);
        });
      },
      child: Icon(
        _voiceEnabled ? Icons.record_voice_over : Icons.voice_over_off,
        size: 20,
      ),
    ),
  ),


// ============================================================================
// TESTING: Simple test to verify voice works
// ============================================================================

// Add this temporary button anywhere in your UI to test:
ElevatedButton(
  onPressed: () {
    final testService = VoiceNavigationService();
    testService.speak("Voice navigation is working! Turn left in 50 meters.");
  },
  child: const Text('Test Voice'),
),

// ============================================================================
// DONE! 
// ============================================================================
// Run: flutter run
// Then navigate to test the voice guidance!
