import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tailor_profile.dart';
import '../models/client.dart';

/// Service for managing tailor business profiles and user data
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String tailorsCollection = 'tailors';
  static const String clientsCollection = 'clients';

  factory ProfileService() {
    return _instance;
  }

  ProfileService._internal();

  /// Get current user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // ==================== Tailor Profile Methods ====================

  /// Create or update tailor profile
  Future<void> saveTailorProfile(TailorProfile profile) async {
    try {
      await _firestore
          .collection(tailorsCollection)
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save tailor profile: $e');
    }
  }

  /// Get tailor profile by UID
  Future<TailorProfile?> getTailorProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(tailorsCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return TailorProfile.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tailor profile: $e');
    }
  }

  /// Get current user's tailor profile
  Future<TailorProfile?> getCurrentTailorProfile() async {
    String? uid = getCurrentUserId();
    if (uid == null) return null;
    return getTailorProfile(uid);
  }

  /// Update specific tailor profile fields
  Future<void> updateTailorProfileFields(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection(tailorsCollection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update tailor profile: $e');
    }
  }

  /// Add portfolio image URL (from Cloudinary)
  /// Pass the Cloudinary image URL directly
  Future<void> addPortfolioImage(String uid, String cloudinaryImageUrl) async {
    try {
      // Add image URL to tailor's portfolio
      await _firestore.collection(tailorsCollection).doc(uid).update({
        'portfolioImageUrls': FieldValue.arrayUnion([cloudinaryImageUrl]),
        'updatedAt': Timestamp.now(),
      });

      // Optionally save reference in CloudinaryService
      // This helps track which images belong to which tailor
    } catch (e) {
      throw Exception('Failed to add portfolio image: $e');
    }
  }

  /// Remove portfolio image URL (from Cloudinary)
  /// Only removes reference from Firebase, image stays on Cloudinary
  Future<void> removePortfolioImage(
    String uid,
    String cloudinaryImageUrl,
  ) async {
    try {
      await _firestore.collection(tailorsCollection).doc(uid).update({
        'portfolioImageUrls': FieldValue.arrayRemove([cloudinaryImageUrl]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to remove portfolio image: $e');
    }
  }

  /// Add business hour
  Future<void> addBusinessHour(String uid, BusinessHours hour) async {
    try {
      await _firestore.collection(tailorsCollection).doc(uid).update({
        'businessHours': FieldValue.arrayUnion([hour.toMap()]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add business hour: $e');
    }
  }

  /// Update business hours
  Future<void> updateBusinessHours(
    String uid,
    List<BusinessHours> hours,
  ) async {
    try {
      await _firestore.collection(tailorsCollection).doc(uid).update({
        'businessHours': hours.map((h) => h.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update business hours: $e');
    }
  }

  /// Search tailors by business name
  Future<List<TailorProfile>> searchTailorsByName(String searchQuery) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(tailorsCollection)
          .where('businessName', isGreaterThanOrEqualTo: searchQuery)
          .where('businessName', isLessThan: searchQuery + 'z')
          .get();

      return snapshot.docs
          .map(
            (doc) => TailorProfile.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search tailors: $e');
    }
  }

  /// Get all tailors (for explore feature)
  Future<List<TailorProfile>> getAllTailors({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(tailorsCollection)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => TailorProfile.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tailors: $e');
    }
  }

  // ==================== Client Profile Methods ====================

  /// Create or update client profile
  Future<void> saveClientProfile(Client client) async {
    try {
      await _firestore
          .collection(clientsCollection)
          .doc(client.uid)
          .set(client.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save client profile: $e');
    }
  }

  /// Get client profile by UID
  Future<Client?> getClientProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(clientsCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return Client.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch client profile: $e');
    }
  }

  /// Get current user's client profile
  Future<Client?> getCurrentClientProfile() async {
    String? uid = getCurrentUserId();
    if (uid == null) return null;
    return getClientProfile(uid);
  }

  /// Update specific client profile fields
  Future<void> updateClientProfileFields(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['lastActiveAt'] = Timestamp.now();
      await _firestore.collection(clientsCollection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update client profile: $e');
    }
  }

  /// Add preferred tailor
  Future<void> addPreferredTailor(String clientUid, String tailorId) async {
    try {
      await _firestore.collection(clientsCollection).doc(clientUid).update({
        'preferredTailorIds': FieldValue.arrayUnion([tailorId]),
      });
    } catch (e) {
      throw Exception('Failed to add preferred tailor: $e');
    }
  }

  /// Remove preferred tailor
  Future<void> removePreferredTailor(String clientUid, String tailorId) async {
    try {
      await _firestore.collection(clientsCollection).doc(clientUid).update({
        'preferredTailorIds': FieldValue.arrayRemove([tailorId]),
      });
    } catch (e) {
      throw Exception('Failed to remove preferred tailor: $e');
    }
  }

  // ==================== User Role Methods ====================

  /// Determine if current user is tailor or client
  Future<String?> getUserRole(String uid) async {
    try {
      // Check if user is in tailors collection
      DocumentSnapshot tailorDoc = await _firestore
          .collection(tailorsCollection)
          .doc(uid)
          .get();
      if (tailorDoc.exists) return 'tailor';

      // Check if user is in clients collection
      DocumentSnapshot clientDoc = await _firestore
          .collection(clientsCollection)
          .doc(uid)
          .get();
      if (clientDoc.exists) return 'client';

      return null;
    } catch (e) {
      throw Exception('Failed to determine user role: $e');
    }
  }

  /// Get current user's role
  Future<String?> getCurrentUserRole() async {
    String? uid = getCurrentUserId();
    if (uid == null) return null;
    return getUserRole(uid);
  }
}
