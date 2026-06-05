import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Toggle this to switch between local Wrangler backend and production.
  static const bool useLocalBackend = true;

  /// Retrieves the backend URL based on the environment and target platform.
  static String get backendUrl {
    if (useLocalBackend) {
      // For local development:
      // If running on an Android Emulator, the host machine is at 10.0.2.2.
      // Otherwise (Web, Desktop, iOS Simulator), localhost is used.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8787';
      }
      return 'http://localhost:8787';
    }
    return 'https://vaulttask-api-worker.jitkhon1979.workers.dev';
  }
}
