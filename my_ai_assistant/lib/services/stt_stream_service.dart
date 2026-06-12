import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'web_audio_service.dart';

class SpeakerUtterance {
  final int speaker;
  String text;
  final DateTime timestamp;

  SpeakerUtterance({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SpeakerUtterance.fromJson(Map<String, dynamic> json) => SpeakerUtterance(
    speaker: json['speaker'] as int,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class SttStreamService extends ChangeNotifier {
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // The list of completed/final utterances
  final List<SpeakerUtterance> _utterances = [];
  List<SpeakerUtterance> get utterances => List.unmodifiable(_utterances);

  // Current active/interim utterance
  SpeakerUtterance? _interimUtterance;
  SpeakerUtterance? get interimUtterance => _interimUtterance;

  void startSession({
    required String backendBaseUrl,
    required bool includeMic,
    required bool includeSystem,
  }) {
    _isRecording = true;
    _errorMessage = null;
    _interimUtterance = null;
    notifyListeners();

    // Convert HTTP/S url to WS/S url
    String socketUrl = backendBaseUrl.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://");
    if (!socketUrl.endsWith("/")) {
      socketUrl += "/api/meetings/stream-stt";
    } else {
      socketUrl += "api/meetings/stream-stt";
    }

    WebAudioService.startRecording(
      socketUrl: socketUrl,
      includeMic: includeMic,
      includeSystem: includeSystem,
      onTranscript: (jsonString) {
        _handleTranscriptJson(jsonString);
      },
      onError: (errorMsg) {
        _errorMessage = errorMsg;
        _isRecording = false;
        notifyListeners();
      },
    );
  }

  void stopSession() {
    WebAudioService.stopRecording();
    _isRecording = false;
    _interimUtterance = null;
    notifyListeners();
  }

  void clearSession() {
    _utterances.clear();
    _interimUtterance = null;
    _errorMessage = null;
    notifyListeners();
  }

  void loadExistingTranscript(String rawTranscript) {
    _utterances.clear();
    _interimUtterance = null;
    if (rawTranscript.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(rawTranscript);
      if (decoded is List) {
        for (var item in decoded) {
          _utterances.add(SpeakerUtterance.fromJson(item));
        }
      }
    } catch (e) {
      // Not JSON list, parse plain text turns like "Speaker 0: Hello\nSpeaker 1: Hi"
      final lines = rawTranscript.split('\n');
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final match = RegExp(r'^Speaker (\d+):\s*(.*)$').firstMatch(line);
        if (match != null) {
          final speaker = int.parse(match.group(1)!);
          final text = match.group(2)!;
          _utterances.add(SpeakerUtterance(
            speaker: speaker,
            text: text,
            timestamp: DateTime.now(),
          ));
        } else {
          _utterances.add(SpeakerUtterance(
            speaker: 0,
            text: line,
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    notifyListeners();
  }

  String getFormattedTranscript() {
    // Return readable transcript turns
    return _utterances.map((u) => "Speaker ${u.speaker}: ${u.text}").join("\n");
  }

  String getJsonTranscript() {
    return jsonEncode(_utterances.map((u) => u.toJson()).toList());
  }

  void _handleTranscriptJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      
      if (data['error'] != null) {
        _errorMessage = data['error'].toString();
        notifyListeners();
        return;
      }

      final channel = data['channel'];
      if (channel == null) return;
      final alternatives = channel['alternatives'];
      if (alternatives == null || alternatives.isEmpty) return;
      
      final alt = alternatives[0];
      final String transcript = alt['transcript'] ?? '';
      final List? words = alt['words'];
      final bool isFinal = data['is_final'] ?? false;

      if (transcript.trim().isEmpty) return;

      if (words != null && words.isNotEmpty) {
        List<Map<String, dynamic>> speakerGroups = [];
        int? currentSpeaker;
        List<String> currentWords = [];

        for (var w in words) {
          final int speaker = w['speaker'] ?? 0;
          final String wordText = w['word'] ?? '';

          if (currentSpeaker == null) {
            currentSpeaker = speaker;
            currentWords.add(wordText);
          } else if (currentSpeaker == speaker) {
            currentWords.add(wordText);
          } else {
            speakerGroups.add({
              'speaker': currentSpeaker,
              'text': currentWords.join(' '),
            });
            currentSpeaker = speaker;
            currentWords = [wordText];
          }
        }

        if (currentSpeaker != null) {
          speakerGroups.add({
            'speaker': currentSpeaker,
            'text': currentWords.join(' '),
          });
        }

        if (isFinal) {
          _interimUtterance = null;
          
          for (var group in speakerGroups) {
            final int speaker = group['speaker'];
            final String text = group['text'];

            if (_utterances.isNotEmpty && _utterances.last.speaker == speaker) {
              _utterances.last.text += " $text";
            } else {
              _utterances.add(SpeakerUtterance(
                speaker: speaker,
                text: text,
                timestamp: DateTime.now(),
              ));
            }
          }
        } else {
          if (speakerGroups.isNotEmpty) {
            _interimUtterance = SpeakerUtterance(
              speaker: speakerGroups.first['speaker'],
              text: speakerGroups.map((g) => g['text']).join(' '),
              timestamp: DateTime.now(),
            );
          }
        }
      } else {
        if (isFinal) {
          _interimUtterance = null;
          _utterances.add(SpeakerUtterance(
            speaker: 0,
            text: transcript,
            timestamp: DateTime.now(),
          ));
        } else {
          _interimUtterance = SpeakerUtterance(
            speaker: 0,
            text: transcript,
            timestamp: DateTime.now(),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error parsing transcript JSON: $e");
    }
  }
}
