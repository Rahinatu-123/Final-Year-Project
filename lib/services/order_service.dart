import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as order_model;
import '../models/order.dart' show OrderStatus;

/// Service for managing order operations with Firebase
class OrderService {
  static final OrderService _instance = OrderService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String ordersCollection = 'orders';
  static const String tailorsCollection = 'tailors';

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  /// Create a new order
  Future<String> createOrder(order_model.Order order) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(ordersCollection)
          .add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Update an existing order
  Future<void> updateOrder(order_model.Order order) async {
    try {
      await _firestore
          .collection(ordersCollection)
          .doc(order.id)
          .update(order.toMap());
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  /// Get a single order by ID
  Future<order_model.Order?> getOrder(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(ordersCollection)
          .doc(orderId)
          .get();
      if (doc.exists) {
        return order_model.Order.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get all pending orders for a tailor
  Future<List<order_model.Order>> getPendingOrdersForTailor(
    String tailorId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(ordersCollection)
          .where('tailorId', isEqualTo: tailorId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => order_model.Order.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending orders: $e');
    }
  }

  /// Get all completed orders for a tailor
  Future<List<order_model.Order>> getCompletedOrdersForTailor(
    String tailorId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(ordersCollection)
          .where('tailorId', isEqualTo: tailorId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => order_model.Order.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed orders: $e');
    }
  }

  /// Get all orders for a tailor (both pending and completed)
  Future<List<order_model.Order>> getAllOrdersForTailor(String tailorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(ordersCollection)
          .where('tailorId', isEqualTo: tailorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => order_model.Order.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Get all orders for a client
  Future<List<order_model.Order>> getOrdersForClient(String clientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(ordersCollection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => order_model.Order.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch client orders: $e');
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(ordersCollection).doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// Stream of pending orders for a tailor (real-time updates)
  Stream<List<order_model.Order>> getPendingOrdersStream(String tailorId) {
    return _firestore
        .collection(ordersCollection)
        .where('tailorId', isEqualTo: tailorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => order_model.Order.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  /// Mark order as completed
  Future<void> completeOrder(String orderId) async {
    try {
      await _firestore.collection(ordersCollection).doc(orderId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to complete order: $e');
    }
  }

  /// Mark order as pending
  Future<void> revertOrderToPending(String orderId) async {
    try {
      await _firestore.collection(ordersCollection).doc(orderId).update({
        'status': 'pending',
        'completedAt': null,
      });
    } catch (e) {
      throw Exception('Failed to revert order: $e');
    }
  }

  /// Get orders with urgent deadlines (1-2 days remaining)
  Future<List<order_model.Order>> getUrgentOrders(String tailorId) async {
    try {
      final orders = await getAllOrdersForTailor(tailorId);
      return orders.where((order) {
        return order.status == OrderStatus.pending &&
            order.daysRemaining() <= 2 &&
            order.daysRemaining() > 0;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch urgent orders: $e');
    }
  }

  /// Get current user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
