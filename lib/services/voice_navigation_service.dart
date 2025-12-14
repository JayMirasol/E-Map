import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for providing voice navigation instructions during campus navigation
class VoiceNavigationService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isEnabled = true;
  Timer? _instructionTimer;

  // Voice settings
  double _volume = 1.0;
  double _speechRate = 0.5; // Slower for clarity
  double _pitch = 1.0;

  VoiceNavigationService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      debugPrint('🔊 Initializing TTS...');

      // Set language FIRST (important for Android)
      final languageResult = await _flutterTts.setLanguage("en-US");
      debugPrint('🔊 Language set result: $languageResult');

      // Configure TTS settings
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);

      // iOS specific settings (will be ignored on Android)
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      // Check available languages
      final languages = await _flutterTts.getLanguages;
      debugPrint('🔊 Available languages: $languages');

      // Set completion handler to debug
      _flutterTts.setCompletionHandler(() {
        debugPrint('🔊 Speech completed');
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('🔊 TTS Error: $msg');
      });

      debugPrint('🔊 TTS initialization complete');
    } catch (e) {
      debugPrint('🔊 Error initializing TTS: $e');
    }
  }

  /// Speak a navigation instruction
  Future<void> speak(String instruction) async {
    debugPrint(
      '🔊 speak() called - Enabled: $_isEnabled, Text: "$instruction"',
    );

    if (!_isEnabled) {
      debugPrint('🔊 Voice is disabled, skipping...');
      return;
    }

    try {
      debugPrint('🔊 Calling TTS speak...');
      final result = await _flutterTts.speak(instruction);
      debugPrint('🔊 TTS speak result: $result');
    } catch (e) {
      debugPrint('🔊 Error speaking instruction: $e');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Announce start of navigation
  Future<void> announceNavigationStart(String destination) async {
    debugPrint('🔊 announceNavigationStart called for: $destination');
    await speak(
      "Starting navigation to $destination. Please follow the blue line on your screen.",
    );
  }

  /// Announce arrival at destination
  Future<void> announceArrival(String destination) async {
    await speak("You have arrived at $destination.");
  }

  /// Generate and announce turn-by-turn instructions from route points
  Future<void> startTurnByTurnNavigation(
    List<Offset> routePoints,
    String destinationName, {
    Duration instructionInterval = const Duration(seconds: 5),
  }) async {
    if (routePoints.length < 2) return;

    // Generate all instructions
    final instructions = _generateInstructions(routePoints, destinationName);

    // Announce first instruction immediately
    if (instructions.isNotEmpty) {
      await speak(instructions[0]);
    }

    // Schedule remaining instructions at intervals
    _instructionTimer?.cancel();
    int instructionIndex = 1;

    _instructionTimer = Timer.periodic(instructionInterval, (timer) async {
      if (instructionIndex >= instructions.length) {
        timer.cancel();
        return;
      }

      await speak(instructions[instructionIndex]);
      instructionIndex++;
    });
  }

  /// Generate navigation instructions from route points
  List<String> _generateInstructions(List<Offset> points, String destination) {
    final instructions = <String>[];

    if (points.length < 3) {
      instructions.add("Head straight to $destination.");
      return instructions;
    }

    instructions.add("Starting navigation to $destination.");

    // Analyze route in segments
    for (int i = 0; i < points.length - 2; i++) {
      final current = points[i];
      final next = points[i + 1];
      final afterNext = points[i + 2];

      // Calculate turn angle
      final angle = _calculateTurnAngle(current, next, afterNext);
      final instruction = _getDirectionInstruction(angle);

      // Only add significant turns (not straight ahead)
      if (instruction != null && !instruction.contains("straight")) {
        // Estimate distance to turn (in arbitrary units, can be calibrated to meters)
        final distance = _calculateDistance(current, next);
        final distanceText = _formatDistance(distance);

        instructions.add("In $distanceText, $instruction.");
      }
    }

    // Final instruction
    final finalDistance = _calculateDistance(
      points[points.length - 2],
      points[points.length - 1],
    );
    instructions.add(
      "In ${_formatDistance(finalDistance)}, you will arrive at $destination.",
    );

    return instructions;
  }

  /// Calculate angle between three points to determine turn direction
  double _calculateTurnAngle(Offset p1, Offset p2, Offset p3) {
    final angle1 = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final angle2 = atan2(p3.dy - p2.dy, p3.dx - p2.dx);

    var angle = (angle2 - angle1) * (180 / pi);

    // Normalize to -180 to 180
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;

    return angle;
  }

  /// Get voice instruction based on turn angle
  String? _getDirectionInstruction(double angle) {
    const threshold = 15.0; // Minimum angle to trigger instruction

    if (angle.abs() < threshold) {
      return "continue straight";
    } else if (angle > 135) {
      return "make a U-turn";
    } else if (angle > 90) {
      return "turn sharp right";
    } else if (angle > 45) {
      return "turn right";
    } else if (angle > threshold) {
      return "bear right";
    } else if (angle < -135) {
      return "make a U-turn";
    } else if (angle < -90) {
      return "turn sharp left";
    } else if (angle < -45) {
      return "turn left";
    } else if (angle < -threshold) {
      return "bear left";
    }

    return null;
  }

  /// Calculate distance between two points
  double _calculateDistance(Offset p1, Offset p2) {
    return sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
  }

  /// Format distance for voice instruction
  String _formatDistance(double distance) {
    // This is in arbitrary units - calibrate based on your map scale
    // For now, using simple thresholds
    if (distance < 50) {
      return "a short distance";
    } else if (distance < 100) {
      return "50 meters";
    } else if (distance < 200) {
      return "100 meters";
    } else {
      return "about ${(distance / 100).round() * 50} meters";
    }
  }

  /// Announce floor change
  Future<void> announceFloorChange(
    int fromFloor,
    int toFloor,
    String connector,
  ) async {
    final direction = toFloor > fromFloor ? "up" : "down";
    final connectorType = connector.toLowerCase().contains("stair")
        ? "stairs"
        : "elevator";

    await speak("Take the $connectorType to go $direction to floor $toFloor.");
  }

  /// Enable/disable voice navigation
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
      _instructionTimer?.cancel();
    }
  }

  /// Adjust voice volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  /// Adjust speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  /// Clean up resources
  void dispose() {
    _instructionTimer?.cancel();
    _flutterTts.stop();
  }
}
