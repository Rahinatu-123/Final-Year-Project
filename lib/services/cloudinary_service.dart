import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for managing Cloudinary image URLs
/// Store image URLs from Cloudinary in Firebase Firestore
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Replace with your Cloudinary details
  static const String cloudinaryCloudName = 'dr8f7af8z';
  static const String cloudinaryUploadPreset = 'fashionHub_app';

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal();

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Upload image file to Cloudinary
  /// Returns the uploaded image URL or null if upload failed
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);

        // Parse JSON response to get secure_url
        // Expected response: {"secure_url": "https://res.cloudinary.com/...", ...}
        if (responseString.contains('secure_url')) {
          // Extract URL from JSON response
          final startIndex = responseString.indexOf('"secure_url":"') + 14;
          final endIndex = responseString.indexOf('"', startIndex);
          final imageUrl = responseString.substring(startIndex, endIndex);

          return imageUrl;
        }
        return null;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Save Cloudinary image URL to Firebase
  /// Store portfolio images, order images, profile images, etc.
  Future<void> saveCloudinaryImageUrl({
    required String imageUrl,
    required String imageType, // 'portfolio', 'order', 'profile', 'post'
    required String referenceId, // uid, orderId, etc.
  }) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      DocumentReference imageDoc = _firestore
          .collection('cloudinary_images')
          .doc(referenceId);

      await imageDoc.set({
        'imageUrl': imageUrl,
        'imageType': imageType,
        'uploadedBy': userId,
        'uploadedAt': Timestamp.now(),
        'cloudName': cloudinaryCloudName,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save image URL: $e');
    }
  }

  /// Get saved Cloudinary image URL from Firebase
  Future<String?> getCloudinaryImageUrl(String referenceId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('cloudinary_images')
          .doc(referenceId)
          .get();

      if (doc.exists) {
        return doc['imageUrl'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch image URL: $e');
    }
  }

  /// Get all portfolio images for a tailor
  Future<List<String>> getPortfolioImages(String tailorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('cloudinary_images')
          .where('imageType', isEqualTo: 'portfolio')
          .where('uploadedBy', isEqualTo: tailorId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['imageUrl'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch portfolio images: $e');
    }
  }

  /// Delete image reference from Firebase
  /// (Note: Image remains on Cloudinary)
  Future<void> deleteImageReference(String referenceId) async {
    try {
      await _firestore
          .collection('cloudinary_images')
          .doc(referenceId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete image reference: $e');
    }
  }

  /// Get all images for an order
  Future<List<String>> getOrderImages(String orderId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('cloudinary_images')
          .where('imageType', isEqualTo: 'order')
          .where('referenceId', isEqualTo: orderId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['imageUrl'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch order images: $e');
    }
  }

  /// Stream portfolio images
  Stream<List<String>> streamPortfolioImages(String tailorId) {
    return _firestore
        .collection('cloudinary_images')
        .where('imageType', isEqualTo: 'portfolio')
        .where('uploadedBy', isEqualTo: tailorId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['imageUrl'] as String).toList(),
        );
  }

  /// Save portfolio post with image
  Future<void> savePortfolioPost({
    required String tailorId,
    required String imageUrl,
    required String description,
    required List<String> tags,
  }) async {
    try {
      String postId = _firestore.collection('portfolio_posts').doc().id;

      await _firestore.collection('portfolio_posts').doc(postId).set({
        'tailorId': tailorId,
        'imageUrl': imageUrl,
        'description': description,
        'tags': tags,
        'createdAt': Timestamp.now(),
        'likes': [],
        'comments': [],
      });

      // Also save image reference
      await saveCloudinaryImageUrl(
        imageUrl: imageUrl,
        imageType: 'post',
        referenceId: postId,
      );
    } catch (e) {
      throw Exception('Failed to save portfolio post: $e');
    }
  }

  /// Get portfolio posts for a tailor
  Future<List<Map<String, dynamic>>> getPortfolioPosts(String tailorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('portfolio_posts')
          .where('tailorId', isEqualTo: tailorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch portfolio posts: $e');
    }
  }

  /// Stream all portfolio posts
  Stream<List<Map<String, dynamic>>> streamAllPortfolioPosts() {
    return _firestore
        .collection('portfolio_posts')
        .orderBy('createdAt', descending: true)
        .limit(50) // Pagination
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('portfolio_posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('portfolio_posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Add comment to post
  Future<void> addCommentToPost(
    String postId,
    String userId,
    String comment,
  ) async {
    try {
      await _firestore.collection('portfolio_posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([
          {'userId': userId, 'comment': comment, 'createdAt': Timestamp.now()},
        ]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Format Cloudinary URL with transformations
  /// Example: resize, crop, quality
  static String getFormattedCloudinaryUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    // Basic URL - you can add transformations as needed
    // Example: https://res.cloudinary.com/cloud_name/image/upload/w_500,h_500,c_fill,q_auto/image_public_id
    return imageUrl; // Return as-is for now
  }
}
