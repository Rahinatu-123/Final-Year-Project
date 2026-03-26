import 'package:flutter/services.dart';

class SecureScreenService {
  static const MethodChannel _channel = MethodChannel('fashionhub/secure_screen');

  static Future<void> setSecureScreen(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecureFlag', {
        'enabled': enabled,
      });
    } catch (_) {
      // Best-effort only. If unsupported on a platform, fail silently.
    }
  }
}
