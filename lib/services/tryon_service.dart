import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';

/// Try-On ML Model Integration Service
/// Calls the remote try-on API endpoint (served via ngrok tunnel)
///
/// API Endpoints:
/// - GET  /health     -- Check if model is loaded and ready
/// - POST /tryon      -- Run the try-on inference with person & garment images
///
/// The API URL is managed via Firebase Remote Config for easy updates

class TryOnService {
  /// Fetch latest API URL from Remote Config before each network call.
  static Future<String> _resolveBaseUrl() async {
    final latest = await RemoteConfigService.fetchLatestApiUrl();
    final baseUrl = _normalizeBaseUrl(
      latest.isNotEmpty ? latest : RemoteConfigService.getApiUrl(),
    );

    if (baseUrl.isEmpty) {
      throw Exception(
        'Remote Config key "api_url" is empty. Set it in Firebase Console and publish the config.',
      );
    }

    return baseUrl;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _isCertificateError(Object error) {
    final msg = error.toString();
    return msg.contains('CERTIFICATE_VERIFY_FAILED') ||
        msg.contains('HandshakeException');
  }

  static Exception _certificateException({
    required String failingUrl,
    required Object originalError,
  }) {
    final host = Uri.tryParse(failingUrl)?.host ?? failingUrl;
    return Exception(
      'SSL certificate verification failed for "$host". '
      'Check that the server provides a valid full certificate chain and that the URL in Remote Config (api_url) is correct. '
      'Original error: $originalError',
    );
  }

  static Future<http.StreamedResponse> _sendTryOnRequest({
    required String baseUrl,
    required String personImagePath,
    required String garmentImagePath,
    required String category,
    required int nSteps,
    required double imageScale,
    required int seed,
    required String resolution,
  }) async {
    final tryonUrl = '$baseUrl/tryon';
    print('🌐 Try-on URL: $tryonUrl');

    final request = http.MultipartRequest('POST', Uri.parse(tryonUrl));

    // Required header to bypass ngrok browser warning page
    request.headers['ngrok-skip-browser-warning'] = 'true';

    // Attach person image (local file)
    print('📤 Adding person image...');
    request.files.add(await http.MultipartFile.fromPath('person', personImagePath));

    // Attach garment image (handle both local files and URLs)
    print('📤 Adding garment image...');
    final isGarmentUrl =
        garmentImagePath.startsWith('http://') ||
        garmentImagePath.startsWith('https://');

    if (isGarmentUrl) {
      // Download URL and attach as bytes
      print('🌐 Downloading garment from URL: $garmentImagePath');
      late final Uint8List imageBytes;
      try {
        imageBytes = await http.readBytes(Uri.parse(garmentImagePath));
      } catch (e) {
        if (_isCertificateError(e)) {
          throw _certificateException(
            failingUrl: garmentImagePath,
            originalError: e,
          );
        }
        rethrow;
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'garment',
          imageBytes,
          filename: 'garment.jpg',
        ),
      );
    } else {
      // Use local file path
      request.files.add(
        await http.MultipartFile.fromPath('garment', garmentImagePath),
      );
    }

    // Optional parameters
    request.fields['category'] = category;
    request.fields['n_steps'] = nSteps.toString();
    request.fields['image_scale'] = imageScale.toString();
    request.fields['seed'] = seed.toString();
    request.fields['resolution'] = resolution;

    print('⏳ Sending request to backend (30-60 seconds)...');

    // Inference takes 30-60 seconds so use a long timeout
    try {
      return request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('❌ Request timeout after 120 seconds');
          throw Exception('Request timeout - backend took too long to respond');
        },
      );
    } catch (e) {
      if (_isCertificateError(e)) {
        throw _certificateException(failingUrl: tryonUrl, originalError: e);
      }
      rethrow;
    }
  }

  // Check if the model is loaded and ready
  static Future<bool> isModelReady() async {
    var healthUrl = 'api_url/health';
    try {
      final baseUrl = await _resolveBaseUrl();
      healthUrl = '$baseUrl/health';
      print('🔍 Checking model health at: $healthUrl');

      final response = await http
          .get(
            Uri.parse(healthUrl),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 10));

      print('✅ Health check response: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Response looks like: {"model_ready": true, "error": null}
        return response.body.contains('"model_ready": true') ||
            response.body.contains('"model_ready":true');
      }
      // For now, allow requests even if health check fails
      // TODO: Enable this when backend is stable
      return true;
    } catch (e) {
      // For now, continue with request regardless of health check failure
      // This allows testing when the backend may be starting up
      print('⚠️ Health check failed: $e');
      if (_isCertificateError(e)) {
        print(
          '💡 SSL verification failed for $healthUrl. Check your backend certificate chain.',
        );
      }
      print('💡 Make sure ngrok is running and api_url in Remote Config is correct.');
      return true;
    }
  }

  // Send person + garment images and get the try-on result
  // personImagePath  -- file path to person photo (local file)
  // garmentImagePath -- file path to garment photo (local file or URL)
  // category         -- 'Upper-body', 'Lower-body', or 'Dresses'
  static Future<Uint8List> tryOn({
    required String personImagePath,
    required String garmentImagePath,
    String category = 'Upper-body',
    int nSteps = 20,
    double imageScale = 2.5,
    int seed = 42,
    String resolution = '768x1024',
  }) async {
    print('🔍 TryOn Debug - Starting try-on process');
    print('📁 Person image: $personImagePath');
    print('📁 Garment image: $garmentImagePath');
    print('👕 Category: $category');

    // Check model is ready before sending
    final ready = await isModelReady();
    if (!ready) {
      throw Exception('Model is not ready yet. Please wait and try again.');
    }

    try {
      final baseUrl = await _resolveBaseUrl();
      var streamedResponse = await _sendTryOnRequest(
        baseUrl: baseUrl,
        personImagePath: personImagePath,
        garmentImagePath: garmentImagePath,
        category: category,
        nSteps: nSteps,
        imageScale: imageScale,
        seed: seed,
        resolution: resolution,
      );

      print('✅ Response received: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final bytes = await streamedResponse.stream.toBytes();
        print('✅ Success! Received ${bytes.length} bytes');
        return bytes;
      } else {
        var body = await streamedResponse.stream.bytesToString();
        print('❌ TryOn Response Status: ${streamedResponse.statusCode}');
        print('❌ TryOn Response Body: $body');

        final isNgrokOffline =
            streamedResponse.statusCode == 404 && body.contains('ERR_NGROK_3200');

        if (isNgrokOffline) {
          print('🔄 Ngrok endpoint is offline. Refreshing Remote Config and retrying once...');
          final refreshedBaseUrl = _normalizeBaseUrl(
            await RemoteConfigService.fetchLatestApiUrl(),
          );

          if (refreshedBaseUrl.isNotEmpty && refreshedBaseUrl != baseUrl) {
            print('✅ Found updated api_url in Remote Config: $refreshedBaseUrl');
            streamedResponse = await _sendTryOnRequest(
              baseUrl: refreshedBaseUrl,
              personImagePath: personImagePath,
              garmentImagePath: garmentImagePath,
              category: category,
              nSteps: nSteps,
              imageScale: imageScale,
              seed: seed,
              resolution: resolution,
            );

            print('✅ Retry response received: ${streamedResponse.statusCode}');

            if (streamedResponse.statusCode == 200) {
              final bytes = await streamedResponse.stream.toBytes();
              print('✅ Success after refresh! Received ${bytes.length} bytes');
              return bytes;
            }

            body = await streamedResponse.stream.bytesToString();
            print('❌ Retry TryOn Response Status: ${streamedResponse.statusCode}');
            print('❌ Retry TryOn Response Body: $body');
          }

          throw Exception(
            'Try-on backend is offline (ERR_NGROK_3200). Update and publish Remote Config key "api_url" with an active server URL.',
          );
        }

        throw Exception(
          'Try-on failed (${streamedResponse.statusCode}): $body',
        );
      }
    } catch (e) {
      if (_isCertificateError(e)) {
        final baseUrl = RemoteConfigService.getApiUrl();
        throw _certificateException(
          failingUrl: baseUrl.isNotEmpty ? baseUrl : 'api_url',
          originalError: e,
        );
      }
      print('❌ TryOn Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      rethrow;
    }
  }
}
