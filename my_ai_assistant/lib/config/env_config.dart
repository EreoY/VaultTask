import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  /// Toggle this to switch between local Wrangler backend and production.
  static bool get useLocalBackend {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return false;
      }
    }
    final val = dotenv.env['USE_LOCAL_BACKEND'];
    if (val != null) {
      return val.toLowerCase() == 'true';
    }
    return true; // Default to local for dev safety
  }

  /// Retrieves the backend URL based on the environment and target platform.
  static String get backendUrl {
    if (useLocalBackend) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return dotenv.get('LOCAL_BACKEND_URL_ANDROID', fallback: 'http://10.0.2.2:8787');
      }
      return dotenv.get('LOCAL_BACKEND_URL_DEFAULT', fallback: 'http://localhost:8787');
    }
    return dotenv.get('PRODUCTION_BACKEND_URL', fallback: 'https://vaulttask-api-worker.jitkhon1979.workers.dev');
  }

  /// Supabase Config
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: 'https://ofaspmhkrykgqxigjmxv.supabase.co');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: 'sb_publishable_aFzFokHfq_MTz8vMGJttww_LaHEphaX');

  /// Firebase Options Config
  static String get firebaseApiKeyWeb => dotenv.get('FIREBASE_API_KEY_WEB', fallback: 'AIzaSyCmpEBLMOPw8pcSJpd4d7TCI3Sj_m4hwnc');
  static String get firebaseAppIdWeb => dotenv.get('FIREBASE_APP_ID_WEB', fallback: '1:294337832265:web:b3faf535b42fc7664c2698');
  static String get firebaseProjectId => dotenv.get('FIREBASE_PROJECT_ID', fallback: 'calenda-ai-app');
  static String get firebaseMessagingSenderId => dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '294337832265');
  static String get firebaseAuthDomain => dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: 'calenda-ai-app.firebaseapp.com');
  static String get firebaseStorageBucket => dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: 'calenda-ai-app.firebasestorage.app');
  static String get firebaseMeasurementIdWeb => dotenv.get('FIREBASE_MEASUREMENT_ID_WEB', fallback: 'G-4H6K9Y38LM');

  static String get firebaseApiKeyAndroid => dotenv.get('FIREBASE_API_KEY_ANDROID', fallback: 'AIzaSyBAB7Mqm4FirYGFM81j9X_WZAN0jr2zLE0');
  static String get firebaseAppIdAndroid => dotenv.get('FIREBASE_APP_ID_ANDROID', fallback: '1:294337832265:android:8f2e1193a125c9124c2698');

  static String get firebaseApiKeyIos => dotenv.get('FIREBASE_API_KEY_IOS', fallback: 'AIzaSyD37G1Umsa_N9h_PggpbapjYeanMMdXnTQ');
  static String get firebaseAppIdIos => dotenv.get('FIREBASE_APP_ID_IOS', fallback: '1:294337832265:ios:50bd10aa415e13a84c2698');
  static String get firebaseIosClientId => dotenv.get('FIREBASE_IOS_CLIENT_ID', fallback: '294337832265-rhapvjri8coucajkebkjnv3nfrkupv3c.apps.googleusercontent.com');
  static String get firebaseIosBundleId => dotenv.get('FIREBASE_IOS_BUNDLE_ID', fallback: 'com.example.myAiAssistant');

  static String get firebaseApiKeyWindows => dotenv.get('FIREBASE_API_KEY_WINDOWS', fallback: 'AIzaSyCmpEBLMOPw8pcSJpd4d7TCI3Sj_m4hwnc');
  static String get firebaseAppIdWindows => dotenv.get('FIREBASE_APP_ID_WINDOWS', fallback: '1:294337832265:web:8825245d47e66af24c2698');
  static String get firebaseMeasurementIdWindows => dotenv.get('FIREBASE_MEASUREMENT_ID_WINDOWS', fallback: 'G-VK669TZLB0');

  /// Sanitizes image URL by replacing https with http for local backend to prevent connection failure.
  static String sanitizeUrl(String url) {
    if (url.startsWith('https://localhost') || 
        url.startsWith('https://127.0.0.1') || 
        url.startsWith('https://10.0.2.2')) {
      return url.replaceFirst('https://', 'http://');
    }
    return url;
  }
}
