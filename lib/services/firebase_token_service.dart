// lib/services/firebase_token_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class FirebaseTokenService {
  static bool _initialized = false;
  static String _githubToken = '';
  static String _geminiApiKey = '';

  /// Initialize Firebase and fetch tokens
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('✅ Firebase already initialized');
      return;
    }

    try {
      debugPrint('🔥 Initializing Firebase...');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          authDomain: FirebaseConfig.authDomain,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          appId: FirebaseConfig.appId,
        ),
      );

      debugPrint('✅ Firebase initialized');

      // Fetch tokens from Firestore
      await _fetchTokens();

      _initialized = true;
      debugPrint('🎉 Firebase token service ready!');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Don't throw - app can still work with cached data
      _initialized = true;
    }
  }

  /// Fetch tokens from Firestore
  static Future<void> _fetchTokens() async {
    try {
      debugPrint('📡 Fetching tokens from Firestore...');

      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('tokens')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firestore timeout'),
          );

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _githubToken = data['githubToken'] as String? ?? '';
          _geminiApiKey = data['geminiApiKey'] as String? ?? '';

          debugPrint(
              '✅ GitHub Token: ${_githubToken.isNotEmpty ? "Loaded (${_githubToken.length} chars)" : "Missing"}');
          debugPrint(
              '✅ Gemini Key: ${_geminiApiKey.isNotEmpty ? "Loaded (${_geminiApiKey.length} chars)" : "Missing"}');
        } else {
          debugPrint('⚠️ Document exists but has no data');
        }
      } else {
        debugPrint('⚠️ Token document does not exist in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error fetching tokens: $e');
      // Don't throw - let app continue with empty tokens
    }
  }

  /// Public getters
  static String get githubToken => _githubToken;
  static String get geminiApiKey => _geminiApiKey;

  static bool get hasGithubToken => _githubToken.isNotEmpty;
  static bool get hasGeminiKey => _geminiApiKey.isNotEmpty;
  static bool get hasAllTokens => hasGithubToken && hasGeminiKey;
  static bool get isInitialized => _initialized;

  /// Refresh tokens from Firestore
  static Future<void> refresh() async {
    if (!_initialized) {
      await initialize();
      return;
    }

    debugPrint('🔄 Refreshing tokens...');
    await _fetchTokens();
  }
}
