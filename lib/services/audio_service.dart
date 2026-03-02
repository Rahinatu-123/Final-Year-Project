import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

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

  /// Upload audio file to Firebase Storage
  Future<String?> uploadAudio(
    File audioFile,
    String chatId,
    String userId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_${userId}_$timestamp.wav';
      final ref = _firebaseStorage.ref('chats/$chatId/audio').child(fileName);

      final uploadTask = ref.putFile(audioFile);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }

  /// Delete audio file from Firebase Storage
  Future<void> deleteAudio(String downloadUrl) async {
    try {
      final ref = _firebaseStorage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting audio: $e');
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
    return '${dir.path}/audio_$timestamp.wav';
  }

  /// Delete local audio file
  Future<void> deleteLocalAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting local audio: $e');
    }
  }
}
