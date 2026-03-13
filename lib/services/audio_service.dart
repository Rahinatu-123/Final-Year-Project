import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'cloudinary_service.dart';

class AudioService {
  static const String _cloudName = CloudinaryService.cloudinaryCloudName;
  static const String _unsignedUploadPreset =
      CloudinaryService.cloudinaryUploadPreset;

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Upload audio file to Cloudinary and return the secure URL
  Future<String?> uploadAudio(
    File audioFile,
    String chatId,
    String userId,
  ) async {
    try {
      if (!audioFile.existsSync()) {
        throw Exception('Audio file does not exist');
      }

      if (_cloudName.trim().isEmpty || _unsignedUploadPreset.trim().isEmpty) {
        throw Exception(
          'Cloudinary is not configured. Set cloudinaryCloudName and cloudinaryUploadPreset in cloudinary_service.dart',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_${userId}_$timestamp.aac';
      final uploadUri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
      );

      final request = http.MultipartRequest('POST', uploadUri)
        ..fields['upload_preset'] = _unsignedUploadPreset
        ..fields['folder'] = 'chats/$chatId/audio'
        ..fields['public_id'] = fileName
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            audioFile.path,
            filename: fileName,
          ),
        );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        throw Exception(
          'Cloudinary upload failed (${streamedResponse.statusCode}): $responseBody',
        );
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = data['secure_url']?.toString();

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary upload succeeded but secure_url was missing');
      }

      return secureUrl;
    } catch (e) {
      throw Exception('Audio upload failed: $e');
    }
  }

  /// Cloudinary unsigned uploads cannot be reliably deleted from the client.
  /// Keep as a no-op for now unless you add a secure backend delete endpoint.
  Future<void> deleteAudio(String downloadUrl) async {
    try {
      if (downloadUrl.isEmpty) return;
    } catch (e) {
      debugPrint('Error deleting audio: $e');
    }
  }

  /// Get temporary directory for storing audio files
  Future<Directory> getAudioDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final audioDir = Directory('${tempDir.path}/audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return audioDir;
  }

  /// Generate audio file path
  Future<String> generateAudioFilePath() async {
    final dir = await getAudioDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/audio_$timestamp.aac';
  }

  /// Delete local audio file
  Future<void> deleteLocalAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local audio: $e');
    }
  }
}
