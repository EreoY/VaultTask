// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class WebAudioService {
  /// Starts recording audio (mic and/or system) and streams it via WebSocket proxy to Deepgram.
  static void startRecording({
    required String socketUrl,
    required bool includeMic,
    required bool includeSystem,
    required Function(String jsonString) onTranscript,
    required Function(String errorMsg) onError,
  }) {
    if (!kIsWeb) {
      onError("Audio streaming is only supported on Web.");
      return;
    }

    try {
      print("WebAudioService: startRecording called");
      print("WebAudioService: js.context is ${js.context}");
      
      final hasRecorder = js.context.hasProperty('webAudioRecorder');
      print("WebAudioService: js.context has webAudioRecorder property: $hasRecorder");
      
      final recorder = js.context['webAudioRecorder'];
      print("WebAudioService: webAudioRecorder object is: $recorder");

      if (recorder == null) {
        onError("JavaScript webAudioRecorder helper is not loaded. hasProperty: $hasRecorder");
        return;
      }

      recorder.callMethod('start', [
        socketUrl,
        includeMic,
        includeSystem,
        // ignore: undefined_function
        js.allowInterop((dynamic data) {
          if (data != null) {
            onTranscript(data.toString());
          }
        }),
        // ignore: undefined_function
        js.allowInterop((dynamic errorMsg) {
          if (errorMsg != null) {
            onError(errorMsg.toString());
          }
        }),
      ]);
    } catch (e) {
      onError("Failed to start JS recording: $e");
    }
  }

  /// Stops recording and closes the WebSocket connection.
  static void stopRecording() {
    if (!kIsWeb) return;
    try {
      final recorder = js.context['webAudioRecorder'];
      if (recorder != null) {
        recorder.callMethod('stop');
      }
    } catch (e) {
      // ignore
    }
  }
}
