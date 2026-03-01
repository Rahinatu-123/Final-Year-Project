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
  /// Get the base API URL dynamically from Firebase Remote Config
  /// This allows updating the URL without rebuilding the app
  static String get baseUrl => RemoteConfigService.getApiUrl();

  // Check if the model is loaded and ready
  static Future<bool> isModelReady() async {
    try {
      final url = '$baseUrl/health';
      print('🔍 Checking model health at: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'ngrok-skip-browser-warning': 'true'})
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
      print('💡 Make sure ngrok is running and baseUrl is correct!');
      print('💡 Current baseUrl: $baseUrl');
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
      final tryonUrl = '$baseUrl/tryon';
      print('🌐 Try-on URL: $tryonUrl');

      final request = http.MultipartRequest('POST', Uri.parse(tryonUrl));

      // Required header to bypass ngrok browser warning page
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Attach person image (local file)
      print('📤 Adding person image...');
      request.files.add(
        await http.MultipartFile.fromPath('person', personImagePath),
      );

      // Attach garment image (handle both local files and URLs)
      print('📤 Adding garment image...');
      final isGarmentUrl =
          garmentImagePath.startsWith('http://') ||
          garmentImagePath.startsWith('https://');

      if (isGarmentUrl) {
        // Download URL and attach as bytes
        print('🌐 Downloading garment from URL: $garmentImagePath');
        final imageBytes = await http.readBytes(Uri.parse(garmentImagePath));
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
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('❌ Request timeout after 120 seconds');
          throw Exception('Request timeout - backend took too long to respond');
        },
      );

      print('✅ Response received: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final bytes = await streamedResponse.stream.toBytes();
        print('✅ Success! Received ${bytes.length} bytes');
        return bytes;
      } else {
        final body = await streamedResponse.stream.bytesToString();
        print('❌ TryOn Response Status: ${streamedResponse.statusCode}');
        print('❌ TryOn Response Body: $body');
        throw Exception(
          'Try-on failed (${streamedResponse.statusCode}): $body',
        );
      }
    } catch (e) {
      print('❌ TryOn Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      rethrow;
    }
  }
}
