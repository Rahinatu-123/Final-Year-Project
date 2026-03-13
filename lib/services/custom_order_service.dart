import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_order.dart';

class CustomOrderService {
  static final CustomOrderService _instance = CustomOrderService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String customOrdersCollection = 'custom_orders';

  factory CustomOrderService() {
    return _instance;
  }

  CustomOrderService._internal();

  /// Create a new custom order for a client
  Future<String> createCustomOrder(CustomOrder customOrder) async {
    try {
      // Ensure tailorId matches authenticated user for security rule compliance
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Override tailorId with current user's UID to match Firestore security rules
      final orderToCreate = CustomOrder(
        id: customOrder.id,
        tailorId: currentUser.uid,
        clientName: customOrder.clientName,
        clientId: customOrder.clientId,
        style: customOrder.style,
        basePrice: customOrder.basePrice,
        measurements: customOrder.measurements,
        daysToDeliver: customOrder.daysToDeliver,
        status: customOrder.status,
        styleImageUrl: customOrder.styleImageUrl,
        createdAt: customOrder.createdAt,
        completedAt: customOrder.completedAt,
        dueDate: customOrder.dueDate,
      );

      DocumentReference docRef = await _firestore
          .collection(customOrdersCollection)
          .add(orderToCreate.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create custom order: $e');
    }
  }

  /// Get all custom orders for a tailor
  Future<List<CustomOrder>> getCustomOrdersByTailorId(String tailorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(customOrdersCollection)
          .where('tailorId', isEqualTo: tailorId)
          .get();

      List<CustomOrder> orders = snapshot.docs
          .map(
            (doc) =>
                CustomOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sort by createdAt descending in memory (no composite index needed)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch custom orders: $e');
    }
  }

  /// Get active custom orders for a tailor
  Future<List<CustomOrder>> getActiveCustomOrders(String tailorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(customOrdersCollection)
          .where('tailorId', isEqualTo: tailorId)
          .where('status', isEqualTo: 'active')
          .get();

      List<CustomOrder> orders = snapshot.docs
          .map(
            (doc) =>
                CustomOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sort by createdAt descending in memory (no composite index needed)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch active custom orders: $e');
    }
  }

  /// Get custom order by ID
  Future<CustomOrder?> getCustomOrderById(String customOrderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(customOrdersCollection)
          .doc(customOrderId)
          .get();

      if (doc.exists) {
        return CustomOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch custom order: $e');
    }
  }

  /// Update custom order
  Future<void> updateCustomOrder(CustomOrder customOrder) async {
    try {
      await _firestore
          .collection(customOrdersCollection)
          .doc(customOrder.id)
          .update(customOrder.toMap());
    } catch (e) {
      throw Exception('Failed to update custom order: $e');
    }
  }

  /// Delete custom order
  Future<void> deleteCustomOrder(String customOrderId) async {
    try {
      await _firestore
          .collection(customOrdersCollection)
          .doc(customOrderId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete custom order: $e');
    }
  }

  /// Delete a custom order
  Future<void> deleteOrder(String customOrderId) async {
    try {
      await _firestore
          .collection(customOrdersCollection)
          .doc(customOrderId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// Mark custom order as delivered
  Future<void> markAsDelivered(String customOrderId) async {
    try {
      await _firestore
          .collection(customOrdersCollection)
          .doc(customOrderId)
          .update({'status': 'delivered', 'completedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to mark as delivered: $e');
    }
  }

  /// Stream of custom orders for a tailor (real-time updates)
  Stream<List<CustomOrder>> getCustomOrdersStream(String tailorId) {
    return _firestore
        .collection(customOrdersCollection)
        .where('tailorId', isEqualTo: tailorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          List<CustomOrder> orders = snapshot.docs
              .map(
                (doc) => CustomOrder.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList();

          // Sort by createdAt descending in memory (no composite index needed)
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get current user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
