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

  /// Ingests a Deepgram *pre-recorded* result (from an uploaded audio/video
  /// file) into the same [SpeakerUtterance] model used by the live stream, so
  /// downstream [getJsonTranscript] / autosave / rendering work unchanged.
  ///
  /// Reads `results.utterances[]` (present when `utterances=true`). Falls back
  /// to `results.channels[0].alternatives[0]` (word-grouping, then the plain
  /// transcript string) when utterances are absent.
  ///
  /// When [replace] is true the existing utterances are cleared first;
  /// otherwise the parsed utterances are appended (default — an uploaded file's
  /// diarization indices are per-source and may not align with prior live
  /// utterances). Returns the newly parsed utterances.
  List<SpeakerUtterance> ingestPrerecordedResult(
    Map<String, dynamic> deepgramJson, {
    bool replace = false,
  }) {
    final parsed = _utterancesFromPrerecorded(deepgramJson);
    if (replace) {
      _utterances.clear();
    }
    _utterances.addAll(parsed);
    _interimUtterance = null;
    notifyListeners();
    return List.unmodifiable(parsed);
  }

  /// Pure (no side-effect) converter from a Deepgram pre-recorded JSON map to a
  /// list of [SpeakerUtterance]. Timing is folded into [SpeakerUtterance.timestamp]
  /// via `base + start` so chronological order is preserved without any model
  /// change. Unit-testable in isolation.
  List<SpeakerUtterance> _utterancesFromPrerecorded(
    Map<String, dynamic> json, {
    DateTime? base,
  }) {
    final DateTime baseTime = base ?? DateTime.now();
    final List<SpeakerUtterance> out = [];

    final results = json['results'];
    if (results is! Map) return out;

    // Primary source: results.utterances[]
    final utterances = results['utterances'];
    if (utterances is List && utterances.isNotEmpty) {
      for (final u in utterances) {
        if (u is! Map) continue;
        final int speaker = (u['speaker'] as num?)?.toInt() ?? 0;
        final String text = ((u['transcript'] as String?) ?? '').trim();
        if (text.isEmpty) continue;
        final double startSec = (u['start'] as num?)?.toDouble() ?? 0.0;
        out.add(SpeakerUtterance(
          speaker: speaker,
          text: text,
          timestamp:
              baseTime.add(Duration(milliseconds: (startSec * 1000).round())),
        ));
      }
      if (out.isNotEmpty) return out;
    }

    // Fallback: results.channels[0].alternatives[0]
    final channels = results['channels'];
    if (channels is List && channels.isNotEmpty) {
      final ch = channels[0];
      final alts = (ch is Map) ? ch['alternatives'] : null;
      if (alts is List && alts.isNotEmpty) {
        final alt = alts[0];
        if (alt is Map) {
          // Fallback A: word-level grouping (mirrors the live algorithm).
          final words = alt['words'];
          if (words is List && words.isNotEmpty) {
            int? currentSpeaker;
            double groupStart = 0.0;
            List<String> currentWords = [];

            void flush() {
              if (currentSpeaker != null && currentWords.isNotEmpty) {
                out.add(SpeakerUtterance(
                  speaker: currentSpeaker,
                  text: currentWords.join(' '),
                  timestamp: baseTime
                      .add(Duration(milliseconds: (groupStart * 1000).round())),
                ));
              }
            }

            for (final w in words) {
              if (w is! Map) continue;
              final int speaker = (w['speaker'] as num?)?.toInt() ?? 0;
              final String wordText = (w['punctuated_word'] as String?) ??
                  (w['word'] as String?) ??
                  '';
              final double wStart = (w['start'] as num?)?.toDouble() ?? 0.0;

              if (currentSpeaker == null) {
                currentSpeaker = speaker;
                groupStart = wStart;
                currentWords = [wordText];
              } else if (currentSpeaker == speaker) {
                currentWords.add(wordText);
              } else {
                flush();
                currentSpeaker = speaker;
                groupStart = wStart;
                currentWords = [wordText];
              }
            }
            flush();
            if (out.isNotEmpty) return out;
          }

          // Fallback B: the plain transcript string as a single utterance.
          final String transcript =
              ((alt['transcript'] as String?) ?? '').trim();
          if (transcript.isNotEmpty) {
            out.add(SpeakerUtterance(
              speaker: 0,
              text: transcript,
              timestamp: baseTime,
            ));
          }
        }
      }
    }

    return out;
  }
}
