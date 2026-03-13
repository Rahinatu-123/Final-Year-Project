import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

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
  static const String _apiUrlKey = 'api_url';
  static String _cachedApiUrl = '';

  /// Initialize Remote Config with defaults and fetch latest values
  static Future<void> initialize() async {
    try {
      // Configure fetch settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          // In debug we allow immediate fetches so Remote Config changes are
          // visible without waiting for cache interval.
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(minutes: 30),
        ),
      );

      // Set default values (fallback if Firebase unavailable)
      await _remoteConfig.setDefaults({
        // Keep empty by default so API URL comes from Firebase Remote Config.
        _apiUrlKey: '',
        'tryon_enabled': true,
        'tryon_timeout_seconds': 120,
      });

      // Fetch and activate latest config from Firebase
      await _remoteConfig.fetchAndActivate();
      _cachedApiUrl = _readApiUrl();

      debugPrint('✅ Remote Config initialized successfully');
      debugPrint('📡 API URL: ${getApiUrl()}');
    } catch (e) {
      debugPrint('⚠️ Remote Config initialization failed: $e');
      debugPrint('💡 Using default values');
    }
  }

  /// Get the Try-On API URL from Remote Config
  /// Returns the Remote Config value. Empty means it is not configured yet.
  static String getApiUrl() {
    try {
      if (_cachedApiUrl.isNotEmpty) {
        return _cachedApiUrl;
      }

      _cachedApiUrl = _readApiUrl();
      return _cachedApiUrl;
    } catch (e) {
      return '';
    }
  }

  /// Force-refresh and return latest API URL from Firebase.
  static Future<String> fetchLatestApiUrl() async {
    await refresh();
    return getApiUrl();
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
      _cachedApiUrl = _readApiUrl();
      debugPrint('✅ Remote Config refreshed');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh Remote Config: $e');
    }
  }

  static String _readApiUrl() {
    final rawValue = _remoteConfig.getString(_apiUrlKey).trim();
    if (rawValue.endsWith('/')) {
      return rawValue.substring(0, rawValue.length - 1);
    }
    return rawValue;
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
