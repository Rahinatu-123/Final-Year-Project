import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tailor_client.dart';

class TailorClientService {
  static final TailorClientService _instance = TailorClientService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory TailorClientService() {
    return _instance;
  }

  TailorClientService._internal();

  /// Create a new tailor client
  Future<String> createClient(TailorClient client) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final clientToCreate = TailorClient(
        id: client.id,
        tailorId: currentUser.uid,
        name: client.name,
        profileImageUrl: client.profileImageUrl,
        createdAt: client.createdAt,
      );

      DocumentReference docRef = await _firestore
          .collection('tailor_clients')
          .doc(currentUser.uid)
          .collection('clients')
          .add(clientToCreate.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create client: $e');
    }
  }

  /// Get all clients for a tailor
  Future<List<TailorClient>> getClientsByTailorId(String tailorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tailor_clients')
          .doc(tailorId)
          .collection('clients')
          .get();

      List<TailorClient> clients = snapshot.docs
          .map(
            (doc) => TailorClient.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Sort by createdAt descending
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clients;
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  /// Get single client
  Future<TailorClient?> getClientById(String tailorId, String clientId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('tailor_clients')
          .doc(tailorId)
          .collection('clients')
          .doc(clientId)
          .get();

      if (!doc.exists) return null;

      return TailorClient.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch client: $e');
    }
  }

  /// Update client
  Future<void> updateClient(
    String tailorId,
    String clientId,
    TailorClient client,
  ) async {
    try {
      await _firestore
          .collection('tailor_clients')
          .doc(tailorId)
          .collection('clients')
          .doc(clientId)
          .update(client.toMap());
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  /// Delete client
  Future<void> deleteClient(String tailorId, String clientId) async {
    try {
      await _firestore
          .collection('tailor_clients')
          .doc(tailorId)
          .collection('clients')
          .doc(clientId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete client: $e');
    }
  }

  /// Get clients stream for real-time updates
  Stream<List<TailorClient>> getClientsStream(String tailorId) {
    return _firestore
        .collection('tailor_clients')
        .doc(tailorId)
        .collection('clients')
        .snapshots()
        .map((snapshot) {
          List<TailorClient> clients = snapshot.docs
              .map(
                (doc) => TailorClient.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // Sort by createdAt descending in memory
          clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return clients;
        });
  }
}
