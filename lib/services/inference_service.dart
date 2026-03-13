import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MeasurementResult {
  final Map<String, double> measurements;
  final Duration inferenceTime;

  const MeasurementResult({
    required this.measurements,
    required this.inferenceTime,
  });
}

class InferenceService {
  static const String _baseUrl = 'https://bodym-server-production.up.railway.app';

  /// Check if the server is reachable.
  Future<bool> isReady() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send photos to the server and get measurements back.
  Future<MeasurementResult> predict({
    required File frontImage,
    required File sideImage,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    final stopwatch = Stopwatch()..start();

    // ── Step 1: Wake up server and wait until ready ────────────────────────
    debugPrint('Waking up server...');
    bool serverReady = false;
    for (int i = 0; i < 20; i++) {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/health'))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          serverReady = true;
          debugPrint('✓ Server is ready');
          break;
        }
        debugPrint('Health returned ${response.statusCode}, retrying... (${i + 1}/20)');
        await Future.delayed(const Duration(seconds: 3));
      } catch (_) {
        debugPrint('Retrying... (${i + 1}/20)');
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    if (!serverReady) {
      throw Exception('Server is unavailable. Please try again.');
    }

    // ── Step 2: Build multipart request ───────────────────────────────────
    Future<http.MultipartRequest> buildPredictRequest() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'front_image',
        frontImage.path,
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'side_image',
        sideImage.path,
      ));

      request.fields['gender'] = gender;
      request.fields['height_cm'] = heightCm.toString();
      request.fields['weight_kg'] = weightKg.toString();

      return request;
    }

    debugPrint('Sending request to: $_baseUrl/predict');

    http.Response? response;
    for (int i = 0; i < 3; i++) {
      final request = await buildPredictRequest();
      debugPrint('Attempt ${i + 1}/3, fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 502) {
        break;
      }

      debugPrint('Predict returned 502, retrying... (${i + 1}/3)');
      await Future.delayed(const Duration(seconds: 4));
    }

    if (response == null) {
      throw Exception('No response from server. Please try again.');
    }

    stopwatch.stop();

    // ── Debug response ─────────────────────────────────────────────────────
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception('Prediction failed: ${json['error']}');
    }

    // ── Step 5: Parse measurements ─────────────────────────────────────────
    final rawMeasurements = json['measurements'] as Map<String, dynamic>;
    final measurements    = rawMeasurements.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    // ── Print results ──────────────────────────────────────────────────────
    debugPrint('');
    debugPrint('══════════════════════════════════════════');
    debugPrint('  Body Measurement Results');
    debugPrint('══════════════════════════════════════════');
    measurements.forEach((key, value) {
      debugPrint('  ${key.padRight(25)} $value cm');
    });
    debugPrint('──────────────────────────────────────────');
    debugPrint('  Server round-trip: ${stopwatch.elapsedMilliseconds} ms');
    debugPrint('══════════════════════════════════════════');

    return MeasurementResult(
      measurements:  measurements,
      inferenceTime: stopwatch.elapsed,
    );
  }
}