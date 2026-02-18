import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's business profile
  Future<DocumentSnapshot?> getBusinessProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      return await _firestore.collection('business').doc(userId).get();
    } catch (e) {
      print('Error getting business profile: $e');
      return null;
    }
  }

  // Create or update business profile
  Future<bool> saveBusinessProfile({
    required String businessName,
    required String description,
    required String phone,
    required String email,
    required String location,
    String? instagram,
    String? bio,
    String? logoUrl,
    double? latitude,
    double? longitude,
    List<String>? services,
    List<String>? specialties,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _firestore.collection('business').doc(userId).set({
        'businessName': businessName,
        'description': description,
        'phone': phone,
        'email': email,
        'location': location,
        'instagram': instagram,
        'bio': bio,
        'logoUrl': logoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'services': services ?? [],
        'specialties': specialties ?? [],
        'ownerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving business profile: $e');
      return false;
    }
  }

  // Upload business logo
  Future<bool> updateBusinessLogo(String logoUrl) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _firestore.collection('business').doc(userId).update({
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating business logo: $e');
      return false;
    }
  }

  // Get all active businesses (for discovery)
  Future<QuerySnapshot> getActiveBusinesses() async {
    return await _firestore
        .collection('business')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
  }

  // Stream for business profile updates
  Stream<DocumentSnapshot> businessProfileStream(String userId) {
    return _firestore.collection('business').doc(userId).snapshots();
  }

  // Delete business profile
  Future<bool> deleteBusinessProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _firestore.collection('business').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting business profile: $e');
      return false;
    }
  }

  // Toggle business active status
  Future<bool> toggleBusinessStatus(bool isActive) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _firestore.collection('business').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling business status: $e');
      return false;
    }
  }
}
