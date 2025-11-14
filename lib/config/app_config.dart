// lib/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static bool _initialized = false;
  static String _githubToken = '';
  static String _geminiKey = '';

  /// Initialize configuration - NEVER throws, always succeeds
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔧 Initializing AppConfig...');

    // Load tokens from compile-time environment variables
    _githubToken = const String.fromEnvironment(
      'GITHUB_TOKEN',
      defaultValue: '',
    );

    _geminiKey = const String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );

    _initialized = true;

    // Log status (without exposing actual tokens)
    debugPrint(
        '🔑 GitHub Token: ${_githubToken.isNotEmpty ? "✓ Available (${_githubToken.length} chars)" : "✗ Missing"}');
    debugPrint(
        '🔑 Gemini Key: ${_geminiKey.isNotEmpty ? "✓ Available (${_geminiKey.length} chars)" : "✗ Missing"}');

    if (!hasAllTokens) {
      debugPrint(
          '⚠️ Running in limited mode - some features may use cached data only');
    }
  }

  /// Public getters
  static String get githubToken => _githubToken;
  static String get geminiKey => _geminiKey;

  static bool get hasGithubToken => _githubToken.isNotEmpty;
  static bool get hasGeminiKey => _geminiKey.isNotEmpty;
  static bool get hasAllTokens => hasGithubToken && hasGeminiKey;
  static bool get isInitialized => _initialized;
}
