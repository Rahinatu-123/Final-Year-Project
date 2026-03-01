import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Remote Configuration Service for FashionHub
/// Manages dynamic configuration values stored in Firebase Remote Config
///
/// Currently used for:
/// - api_url: The try-on API endpoint (ngrok tunnel URL)
///
/// Benefits:
/// - Update API endpoints without rebuilding the app
/// - A/B testing capabilities
/// - Feature flags for gradual rollouts

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with defaults and fetch latest values
  static Future<void> initialize() async {
    try {
      // Configure fetch settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      // Set default values (fallback if Firebase unavailable)
      await _remoteConfig.setDefaults({
        'api_url': 'https://unexcepted-coaly-candie.ngrok-free.dev',
        'tryon_enabled': true,
        'tryon_timeout_seconds': 120,
      });

      // Fetch and activate latest config from Firebase
      await _remoteConfig.fetchAndActivate();

      print('✅ Remote Config initialized successfully');
      print('📡 API URL: ${getApiUrl()}');
    } catch (e) {
      print('⚠️ Remote Config initialization failed: $e');
      print('💡 Using default values');
    }
  }

  /// Get the Try-On API URL from Remote Config
  /// Returns the ngrok tunnel URL or fallback URL if unavailable
  static String getApiUrl() {
    try {
      return _remoteConfig.getString('api_url');
    } catch (e) {
      return 'https://unexcepted-coaly-candie.ngrok-free.dev';
    }
  }

  /// Check if Try-On feature is enabled
  static bool isTryOnEnabled() {
    try {
      return _remoteConfig.getBool('tryon_enabled');
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Get Try-On request timeout in seconds
  static int getTryOnTimeout() {
    try {
      final timeout = _remoteConfig.getInt('tryon_timeout_seconds');
      return timeout > 0 ? timeout : 120; // Default to 120 seconds if invalid
    } catch (e) {
      return 120; // Default timeout
    }
  }

  /// Manually refresh config from Firebase
  /// Useful for testing or force-updating config
  static Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('✅ Remote Config refreshed');
    } catch (e) {
      print('⚠️ Failed to refresh Remote Config: $e');
    }
  }

  /// Get all config values for debugging
  static Map<String, dynamic> getAllValues() {
    return {
      'api_url': getApiUrl(),
      'tryon_enabled': isTryOnEnabled(),
      'tryon_timeout_seconds': getTryOnTimeout(),
    };
  }
}
