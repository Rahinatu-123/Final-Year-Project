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

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizePhone(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  String _normalizeEmail(String? value) {
    if (value == null) return '';
    return value.trim().toLowerCase();
  }

  CollectionReference<Map<String, dynamic>> _clientsRef(String tailorId) {
    return _firestore
        .collection('tailor_clients')
        .doc(tailorId)
        .collection('clients');
  }

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
        phone: _normalizePhone(client.phone),
        email: _normalizeEmail(client.email),
        nameKey: _normalizeName(client.name),
        profileImageUrl: client.profileImageUrl,
        createdAt: client.createdAt,
        updatedAt: DateTime.now(),
        totalOrders: client.totalOrders,
      );

      DocumentReference docRef = await _clientsRef(
        currentUser.uid,
      ).add(clientToCreate.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create client: $e');
    }
  }

  /// Create a client or merge with an existing one for repeat orders.
  /// Matching priority: phone -> email -> normalized name.
  Future<String> createOrGetClientForOrder(TailorClient inputClient) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final nameKey = _normalizeName(inputClient.name);
      final phone = _normalizePhone(inputClient.phone);
      final email = _normalizeEmail(inputClient.email);
      final clientsRef = _clientsRef(currentUser.uid);

      final snapshot = await clientsRef.get();
      QueryDocumentSnapshot<Map<String, dynamic>>? match;

      if (phone.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final existingPhone = _normalizePhone(doc.data()['phone'] as String?);
          if (existingPhone.isNotEmpty && existingPhone == phone) {
            match = doc;
            break;
          }
        }
      }

      if (match == null && email.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final existingEmail = _normalizeEmail(doc.data()['email'] as String?);
          if (existingEmail.isNotEmpty && existingEmail == email) {
            match = doc;
            break;
          }
        }
      }

      if (match == null && nameKey.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final existingNameKey = _normalizeName(
            (doc.data()['name'] ?? '') as String,
          );
          if (existingNameKey == nameKey) {
            match = doc;
            break;
          }
        }
      }

      if (match != null) {
        final data = match.data();
        await clientsRef.doc(match.id).update({
          'name': inputClient.name.trim(),
          'nameKey': nameKey,
          'phone': phone.isNotEmpty ? phone : (data['phone'] ?? ''),
          'email': email.isNotEmpty ? email : (data['email'] ?? ''),
          'updatedAt': Timestamp.fromDate(now),
          'lastOrderAt': Timestamp.fromDate(now),
          'totalOrders': FieldValue.increment(1),
        });
        return match.id;
      }

      final clientToCreate = TailorClient(
        id: '',
        tailorId: currentUser.uid,
        name: inputClient.name.trim(),
        phone: phone,
        email: email,
        nameKey: nameKey,
        profileImageUrl: inputClient.profileImageUrl,
        createdAt: now,
        updatedAt: now,
        lastOrderAt: now,
        totalOrders: 1,
      );

      final docRef = await clientsRef.add(clientToCreate.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add/merge client: $e');
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
