import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn(
    scopes: ['email'],
  );

  // ปัจจุบันดึง User ที่ล็อกอินได้จากตรงนี้
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth's native popup provider for Web to avoid origin/popup_closed errors.
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        if (userCredential.user != null) {
          await _registerUserToCloudflare(userCredential.user!);
        }
        return userCredential;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
           await _registerUserToCloudflare(user);
        }
        return userCredential;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && _googleSignIn != null) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // ─── User API Key Storage (per-device) ──────────────────────────
  Future<void> saveUserApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_api_key', key);
  }

  Future<String?> loadUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_api_key');
  }

  Future<void> clearUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_api_key');
  }

  // ─── Cloudflare Workers AI Token Storage ──────────────────────────
  Future<void> saveCfApiToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cf_api_token', token);
  }

  Future<String?> loadCfApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cf_api_token');
  }

  Future<void> clearCfApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cf_api_token');
  }

  Future<void> _registerUserToCloudflare(User user) async {
     final endpointUrl = EnvConfig.backendUrl;
     try {
       final response = await http.post(
          Uri.parse('$endpointUrl/api/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': user.uid,
            'email': user.email,
            'display_name': user.displayName,
          }),
       );
       if (response.statusCode != 200) {
         print('Failed to save to D1: ${response.statusCode} - ${response.body}');
       } else {
         print('Save to D1 Success!');
       }
     } catch (e) {
       print('Failed to register user to Cloudflare: $e');
     }
  }
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _registerUserToCloudflare(user);
  }
}
