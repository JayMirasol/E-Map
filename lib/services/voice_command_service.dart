import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_navigation_service.dart';

/// Service for handling speech recognition and voice commands
/// Allows users to speak their start and destination locations
class VoiceCommandService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceNavigationService _voiceNav;

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';

  VoiceCommandService(this._voiceNav);

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🎤 Initializing speech recognition...');
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Speech recognition error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        debugPrint('✅ Speech recognition initialized successfully');
      } else {
        debugPrint('❌ Speech recognition initialization failed');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Start listening for voice commands
  /// Returns the recognized text when listening completes
  Future<String?> listenForCommand({
    required Function(String) onResult,
    required Function(String) onError,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available on this device');
        await _voiceNav.speak(
          'Sorry, speech recognition is not available on this device.',
        );
        return null;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return null;
    }

    try {
      _lastRecognizedText = '';
      _isListening = true;

      // Announce that we're listening
      await _voiceNav.speak(
        'Listening. Please say your start and destination room.',
      );

      // Wait for the TTS to finish and give user time to prepare
      await Future.delayed(const Duration(milliseconds: 1500));

      debugPrint('🎤 Starting to listen...');

      await _speech.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          debugPrint(
            '🎤 Recognized: $_lastRecognizedText (final: ${result.finalResult})',
          );

          if (result.finalResult) {
            _isListening = false;
            onResult(_lastRecognizedText);
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return _lastRecognizedText.isNotEmpty ? _lastRecognizedText : null;
    } catch (e) {
      debugPrint('❌ Error during speech recognition: $e');
      _isListening = false;
      onError('Failed to recognize speech: $e');
      return null;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      debugPrint('🎤 Stopped listening');
    }
  }

  /// Parse voice command to extract start and destination room names
  /// Expected formats:
  /// - "from [start] to [destination]"
  /// - "navigate from [start] to [destination]"
  /// - "[start] to [destination]"
  /// - "start at [start] end at [destination]"
  /// - "start [start] destination [destination]"
  ParsedCommand parseCommand(String text, List<String> availableRooms) {
    final lowerText = text.toLowerCase().trim();
    debugPrint('🔍 Parsing command: "$lowerText"');

    String? startRoom;
    String? destRoom;

    // Pattern 1: "from X to Y"
    final fromToPattern = RegExp(
      r'(?:navigate\s+)?from\s+(.+?)\s+to\s+(.+)',
      caseSensitive: false,
    );
    final fromToMatch = fromToPattern.firstMatch(lowerText);
    if (fromToMatch != null) {
      final potentialStart = fromToMatch.group(1)!.trim();
      final potentialDest = fromToMatch.group(2)!.trim();
      startRoom = _findBestMatch(potentialStart, availableRooms);
      destRoom = _findBestMatch(potentialDest, availableRooms);
      debugPrint(
        '🔍 Pattern "from-to": start="$potentialStart" -> "$startRoom", dest="$potentialDest" -> "$destRoom"',
      );
    }

    // Pattern 2: "X to Y"
    if (startRoom == null || destRoom == null) {
      final toPattern = RegExp(r'^(.+?)\s+to\s+(.+)$', caseSensitive: false);
      final toMatch = toPattern.firstMatch(lowerText);
      if (toMatch != null) {
        final potentialStart = toMatch.group(1)!.trim();
        final potentialDest = toMatch.group(2)!.trim();
        startRoom = _findBestMatch(potentialStart, availableRooms);
        destRoom = _findBestMatch(potentialDest, availableRooms);
        debugPrint(
          '🔍 Pattern "to": start="$potentialStart" -> "$startRoom", dest="$potentialDest" -> "$destRoom"',
        );
      }
    }

    // Pattern 3: "start at X end at Y" or "start X destination Y"
    if (startRoom == null || destRoom == null) {
      final startEndPattern = RegExp(
        r'start\s+(?:at\s+)?(.+?)(?:\s+(?:end|destination)\s+(?:at\s+)?(.+))',
        caseSensitive: false,
      );
      final startEndMatch = startEndPattern.firstMatch(lowerText);
      if (startEndMatch != null) {
        final potentialStart = startEndMatch.group(1)!.trim();
        final potentialDest = startEndMatch.group(2)!.trim();
        startRoom = _findBestMatch(potentialStart, availableRooms);
        destRoom = _findBestMatch(potentialDest, availableRooms);
        debugPrint(
          '🔍 Pattern "start-end": start="$potentialStart" -> "$startRoom", dest="$potentialDest" -> "$destRoom"',
        );
      }
    }

    return ParsedCommand(
      originalText: text,
      startRoom: startRoom,
      destinationRoom: destRoom,
      isValid: startRoom != null && destRoom != null,
    );
  }

  /// Find the best matching room name from available rooms
  /// Uses fuzzy matching to handle slight variations in pronunciation
  String? _findBestMatch(String spokenText, List<String> availableRooms) {
    if (availableRooms.isEmpty) return null;

    final spoken = spokenText.toLowerCase().trim();

    // First try exact match
    for (final room in availableRooms) {
      if (room.toLowerCase() == spoken) {
        return room;
      }
    }

    // Try contains match
    for (final room in availableRooms) {
      if (room.toLowerCase().contains(spoken) ||
          spoken.contains(room.toLowerCase())) {
        return room;
      }
    }

    // Try fuzzy match by comparing words
    final spokenWords = spoken.split(RegExp(r'\s+'));
    int bestScore = 0;
    String? bestMatch;

    for (final room in availableRooms) {
      final roomWords = room.toLowerCase().split(RegExp(r'\s+'));
      int score = 0;

      for (final spokenWord in spokenWords) {
        for (final roomWord in roomWords) {
          if (roomWord.contains(spokenWord) || spokenWord.contains(roomWord)) {
            score++;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = room;
      }
    }

    // Only return match if we have a reasonable confidence
    if (bestScore > 0) {
      return bestMatch;
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
  }
}

/// Represents a parsed voice command
class ParsedCommand {
  final String originalText;
  final String? startRoom;
  final String? destinationRoom;
  final bool isValid;

  ParsedCommand({
    required this.originalText,
    this.startRoom,
    this.destinationRoom,
    required this.isValid,
  });

  @override
  String toString() {
    return 'ParsedCommand(original: "$originalText", start: $startRoom, dest: $destinationRoom, valid: $isValid)';
  }
}
