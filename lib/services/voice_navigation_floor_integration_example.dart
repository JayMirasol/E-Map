/// EXAMPLE: How to integrate VoiceNavigationService into FloorMapScreen
///
/// This shows how to add voice guidance for indoor floor-by-floor navigation

import 'voice_navigation_service.dart';

/// STEP 1: Add voice service field to _FloorMapScreenState
/// ```dart
/// class _FloorMapScreenState extends State<FloorMapScreen> with TickerProviderStateMixin {
///   // ... existing fields ...
///
///   // Voice navigation
///   final VoiceNavigationService _voiceNav = VoiceNavigationService();
///   bool _voiceEnabled = true;
/// ```

/// STEP 2: Add to dispose()
/// ```dart
/// @override
/// void dispose() {
///   _voiceNav.dispose();
///   // ... rest of dispose ...
/// }
/// ```

/// STEP 3: Announce floor navigation start
/// When pathfinding starts on a floor, add:
/// ```dart
/// void _startFloorNavigation() {
///   // ... existing pathfinding code ...
///
///   if (_voiceEnabled && _destinationRoomId != null) {
///     final destRoom = _getRoomById(_destinationRoomId!);
///     if (destRoom != null) {
///       _voiceNav.announceNavigationStart(destRoom.name);
///     }
///   }
/// }
/// ```

/// STEP 4: Announce floor changes
/// When user needs to change floors, in your floor transition logic:
/// ```dart
/// void _handleFloorTransition(int nextFloor, String connectorType) {
///   // Announce the floor change
///   if (_voiceEnabled) {
///     _voiceNav.announceFloorChange(
///       widget.floorNumber,
///       nextFloor,
///       connectorType,
///     );
///   }
///
///   // ... rest of floor transition code ...
/// }
/// ```

/// STEP 5: Announce when continuing navigation on new floor
/// After floor change completes:
/// ```dart
/// void _continueNavigationOnNewFloor() {
///   if (_voiceEnabled && _destinationRoomId != null) {
///     final destRoom = _getRoomById(_destinationRoomId!);
///     if (destRoom != null) {
///       _voiceNav.speak("Continue following the path to ${destRoom.name}");
///     }
///   }
///
///   // Start turn-by-turn for this floor's route segment
///   if (_voiceEnabled && _currentRoutePoints != null) {
///     _voiceNav.startTurnByTurnNavigation(
///       _currentRoutePoints!,
///       destRoom!.name,
///     );
///   }
/// }
/// ```

/// STEP 6: Add voice button to floor map UI
/// In your build method, add a floating action button:
/// ```dart
/// Stack(
///   children: [
///     // ... existing map widgets ...
///
///     Positioned(
///       top: 80,  // Below other controls
///       right: 16,
///       child: FloatingActionButton(
///         mini: true,
///         heroTag: 'voice_btn',
///         backgroundColor: _voiceEnabled ? Colors.blue.shade700 : Colors.grey,
///         onPressed: () {
///           setState(() {
///             _voiceEnabled = !_voiceEnabled;
///             _voiceNav.setEnabled(_voiceEnabled);
///           });
///         },
///         child: Icon(
///           _voiceEnabled ? Icons.record_voice_over : Icons.voice_over_off,
///           size: 20,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```

/// STEP 7: Add voice instructions to route instructions list
/// When generating _routeInstructions, also speak them:
/// ```dart
/// void _generateRouteInstructions() {
///   // ... existing instruction generation ...
///
///   // After instructions are generated, speak the first few
///   if (_voiceEnabled && _routeInstructions.isNotEmpty) {
///     _voiceNav.speak(_routeInstructions[0]);
///   }
/// }
/// ```

/// COMPLETE EXAMPLE for announcing navigation with distance:
void exampleAnnounceWithDistance(
  VoiceNavigationService voiceNav,
  double estimatedWalkingTime, // in minutes
  String destinationName,
) {
  final timeText = estimatedWalkingTime < 1
      ? "less than a minute"
      : "${estimatedWalkingTime.round()} minutes";

  voiceNav.speak(
    "Starting navigation to $destinationName. "
    "Estimated walking time: $timeText. "
    "Please follow the blue line on your screen.",
  );
}

/// EXAMPLE: Custom instruction for specific landmarks
void exampleCustomLandmarkInstruction(VoiceNavigationService voiceNav) {
  voiceNav.speak(
    "Pass through the main lobby, then turn right at the cafeteria entrance.",
  );
}

/// EXAMPLE: Warning for stairs/elevators
void exampleAccessibilityWarning(
  VoiceNavigationService voiceNav,
  bool hasStairs,
  bool hasElevator,
) {
  if (hasStairs && !hasElevator) {
    voiceNav.speak(
      "Note: This route includes stairs. "
      "Please use an alternative route if you need elevator access.",
    );
  }
}
