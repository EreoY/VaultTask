import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/env_config.dart';
import '../databases/api_cloudflare.dart';
import 'stt_stream_service.dart';

/// Lifecycle stages emitted while picking + transcribing a media file.
enum MeetingTranscriptionStage {
  picking,
  uploading,
  transcribing,
  ingesting,
  done,
  cancelled,
  error,
}

/// Progress callback contract. [message] carries a human-readable status string
/// (already localized-friendly) the UI can surface verbatim.
typedef MeetingTranscriptionProgress = void Function(
  MeetingTranscriptionStage stage, {
  String? message,
});

/// Thrown when the upload/transcription pipeline fails. Keeps a clean,
/// user-facing [message] so the presentation layer can show it directly.
class MeetingTranscriptionException implements Exception {
  final String message;
  MeetingTranscriptionException(this.message);
  @override
  String toString() => message;
}

/// Result of a successful pick → transcribe → ingest cycle.
class MeetingTranscriptionResult {
  /// The newly parsed utterances produced by this file.
  final List<SpeakerUtterance> utterances;

  /// Public R2 URL of the uploaded media (URL mode only; null in bytes mode).
  final String? mediaUrl;

  /// Original picked file name.
  final String? fileName;

  /// Detected MIME type of the picked file.
  final String? mimeType;

  /// 'url' (large-file / production) or 'bytes' (small-file / local dev).
  final String mode;

  final Map<String, String>? takeMap;

  MeetingTranscriptionResult({
    required this.utterances,
    required this.mode,
    this.mediaUrl,
    this.fileName,
    this.mimeType,
    this.takeMap,
  });
}

/// UI-free orchestration for transcribing an uploaded audio/video file into a
/// meeting transcript. Intentionally takes NO [BuildContext] so it stays
/// unit-testable. See docs/meeting-audio-upload-plan.md.
class MeetingTranscriptionService {
  /// Audio + video extensions accepted by the file picker. Deepgram governs
  /// the final accepted format set; unsupported files surface its error.
  static const List<String> allowedExtensions = [
    // audio
    'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus', 'wma',
    // video
    'mp4', 'mov', 'webm', 'mkv', 'm4v', 'avi',
  ];

  /// Pick a media file, upload/transcribe it (mode auto-selected), and return the
  /// parsed utterances and takeMap.
  ///
  /// Returns `null` when the user cancels the file picker.
  /// Throws [MeetingTranscriptionException] on any pipeline failure.
  static Future<MeetingTranscriptionResult?> pickAndTranscribe({
    required String meetingId,
    MeetingTranscriptionProgress? onProgress,
  }) async {
    try {
      // 1) Pick an audio OR video file.
      onProgress?.call(MeetingTranscriptionStage.picking,
          message: 'Selecting file...');
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        debugPrint('[Transcribe] Picker cancelled by user.');
        onProgress?.call(MeetingTranscriptionStage.cancelled);
        return null;
      }

      final file = picked.files.first;
      final raw = file.bytes;
      if (raw == null || raw.isEmpty) {
        throw MeetingTranscriptionException(
          'Could not read the selected file bytes.',
        );
      }
      final bytes = Uint8List.fromList(raw);
      final mime = _mimeForExtension(file.extension);
      debugPrint(
        '[Transcribe] Picked "${file.name}" '
        '(${bytes.lengthInBytes} bytes, mime=$mime)',
      );

      // 2) Mode selection.
      //    PRIMARY (large-file capable): upload to R2 and let Deepgram fetch
      //    the public URL directly, so big media never streams through the
      //    worker.
      //    FALLBACK (bytes): used for small files, local dev (Deepgram cannot
      //    reach a miniflare/localhost R2 URL), or when the R2 upload / URL
      //    transcription step fails — we stream the raw bytes to the worker.
      const int smallFileThreshold = 8 * 1024 * 1024; // 8 MB
      final bool isSmallFile = bytes.lengthInBytes < smallFileThreshold;
      final bool localBackend = _isLocalBackend(EnvConfig.backendUrl);
      final bool preferBytes = isSmallFile || localBackend;

      late final Map<String, dynamic> deepgramJson;
      String? mediaUrl;
      late final String mode;

      if (preferBytes) {
        // FALLBACK bytes mode (small file / local dev).
        debugPrint(
          '[Transcribe] Bytes mode '
          '(small=$isSmallFile, local=$localBackend).',
        );
        onProgress?.call(MeetingTranscriptionStage.transcribing,
            message: 'Transcribing...');
        final res = await ApiCloudflare().transcribeMeetingFile(
          bytes: bytes,
          mimeType: mime,
          language: 'th',
          meetingId: meetingId,
        );
        deepgramJson = _extractDeepgramJson(res);
        mode = 'bytes';
      } else {
        // PRIMARY large-file URL mode, with automatic bytes fallback if the
        // R2 upload (or URL transcription) fails.
        try {
          // 2a) Upload media to R2 (folder 'meetings') → get public URL.
          onProgress?.call(MeetingTranscriptionStage.uploading,
              message: 'Uploading media...');
          final uploadRes = await ApiCloudflare.uploadMeetingMedia(
            bytes,
            file.name,
            mimeType: mime,
          );
          final uploadedUrl = uploadRes['url']?.toString();
          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            throw MeetingTranscriptionException(
              'Upload succeeded but no media URL was returned.',
            );
          }
          mediaUrl = uploadedUrl;
          debugPrint('[Transcribe] Uploaded → $mediaUrl');

          // 2b) Transcribe by URL (Deepgram fetches R2 itself).
          onProgress?.call(MeetingTranscriptionStage.transcribing,
              message: 'Transcribing...');
          final res = await ApiCloudflare().transcribeMeetingFile(
            url: mediaUrl,
            language: 'th',
            meetingId: meetingId,
          );
          deepgramJson = _extractDeepgramJson(res);
          mode = 'url';
        } catch (e) {
          // R2 upload / URL transcription failed → stream raw bytes instead.
          debugPrint(
            '[Transcribe] URL path failed ($e) → falling back to bytes mode.',
          );
          mediaUrl = null;
          onProgress?.call(MeetingTranscriptionStage.transcribing,
              message: 'Transcribing...');
          final res = await ApiCloudflare().transcribeMeetingFile(
            bytes: bytes,
            mimeType: mime,
            language: 'th',
            meetingId: meetingId,
          );
          deepgramJson = _extractDeepgramJson(res);
          mode = 'bytes';
        }
      }

      // 3) Parse utterances and construct the take map.
      onProgress?.call(MeetingTranscriptionStage.ingesting,
          message: 'Adding to transcript...');
      final utterances = SttStreamService.utterancesFromPrerecorded(deepgramJson);

      final takeMap = {
        'id': const Uuid().v4(),
        'type': 'recording',
        'name': file.name,
        'url': mediaUrl ?? '',
        'mime': mime,
        'transcript': jsonEncode(utterances.map((u) => u.toJson()).toList()),
      };

      debugPrint('[Transcribe] Parsed ${utterances.length} utterance(s).');

      onProgress?.call(MeetingTranscriptionStage.done);
      return MeetingTranscriptionResult(
        utterances: utterances,
        mode: mode,
        mediaUrl: mediaUrl,
        fileName: file.name,
        mimeType: mime,
        takeMap: takeMap,
      );
    } on MeetingTranscriptionException catch (e) {
      debugPrint('[Transcribe][Error] $e');
      onProgress?.call(MeetingTranscriptionStage.error, message: e.message);
      rethrow;
    } catch (e) {
      debugPrint('[Transcribe][Error] $e');
      onProgress?.call(MeetingTranscriptionStage.error, message: e.toString());
      throw MeetingTranscriptionException(e.toString());
    }
  }

  /// Worker wraps Deepgram output as `{success, mode, result}`. Be tolerant of
  /// either the wrapped envelope or a raw Deepgram JSON body.
  static Map<String, dynamic> _extractDeepgramJson(Map<String, dynamic> res) {
    final inner = res['result'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    return res;
  }

  /// Deepgram cannot fetch a miniflare/localhost R2 URL, so local backends must
  /// use bytes mode.
  static bool _isLocalBackend(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? url.toLowerCase();
    return host.contains('localhost') ||
        host.contains('127.0.0.1') ||
        host.contains('10.0.2.2');
  }

  static String _mimeForExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'opus':
        return 'audio/opus';
      case 'wma':
        return 'audio/x-ms-wma';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'm4v':
        return 'video/x-m4v';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}
