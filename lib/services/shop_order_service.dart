import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_order.dart';

class ShopOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all shop orders for a tailor (one-time fetch)
  Future<List<ShopOrder>> getTailorOrders(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection('shop_orders')
          .where('tailorId', isEqualTo: tailorId)
          .get();

      final orders = snapshot.docs
          .map((doc) => ShopOrder.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw Exception('Failed to get tailor shop orders: $e');
    }
  }

  /// Create a new shop order
  Future<String> createOrder(ShopOrder order) async {
    try {
      final docRef = await _firestore
          .collection('shop_orders')
          .add(order.toMap());

      // Also add to customer's orders subcollection
      await _firestore
          .collection('users')
          .doc(order.customerId)
          .collection('shop_orders')
          .doc(docRef.id)
          .set({'orderId': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get all orders for a tailor
  Stream<List<ShopOrder>> getTailorOrdersStream(String tailorId) {
    return _firestore
        .collection('shop_orders')
        .where('tailorId', isEqualTo: tailorId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => ShopOrder.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side by createdAt descending
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get orders for a tailor by status
  Stream<List<ShopOrder>> getTailorOrdersByStatusStream(
    String tailorId,
    ShopOrderStatus status,
  ) {
    return _firestore
        .collection('shop_orders')
        .where('tailorId', isEqualTo: tailorId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => ShopOrder.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side by createdAt descending
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get all orders for a customer
  Stream<List<ShopOrder>> getCustomerOrdersStream(String customerId) {
    return _firestore
        .collection('shop_orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => ShopOrder.fromMap(doc.data(), doc.id))
              .toList();
          // Remove duplicates by ID
          final seenIds = <String>{};
          final uniqueOrders = <ShopOrder>[];
          for (var order in orders) {
            if (seenIds.add(order.id)) {
              uniqueOrders.add(order);
            }
          }
          // Sort client-side by createdAt descending
          uniqueOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return uniqueOrders;
        });
  }

  /// Get a single order
  Future<ShopOrder?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('shop_orders').doc(orderId).get();
      if (doc.exists) {
        return ShopOrder.fromMap(doc.data()!, orderId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    ShopOrderStatus newStatus, {
    DateTime? date,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus.toString().split('.').last,
      };

      // Add appropriate timestamp based on status
      switch (newStatus) {
        case ShopOrderStatus.confirmed:
          updateData['confirmedAt'] = date ?? FieldValue.serverTimestamp();
          break;
        case ShopOrderStatus.inProgress:
          updateData['startedAt'] = date ?? FieldValue.serverTimestamp();
          break;
        case ShopOrderStatus.completed:
          updateData['completedAt'] = date ?? FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore
          .collection('shop_orders')
          .doc(orderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Update tailor notes
  Future<void> updateTailorNotes(String orderId, String notes) async {
    try {
      await _firestore.collection('shop_orders').doc(orderId).update({
        'tailorNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to update notes: $e');
    }
  }

  /// Add progress images
  Future<void> addProgressImage(String orderId, String imageUrl) async {
    try {
      final order = await getOrder(orderId);
      if (order != null) {
        final updatedImages = [...order.progressImages, imageUrl];
        await _firestore.collection('shop_orders').doc(orderId).update({
          'progressImages': updatedImages,
        });
      }
    } catch (e) {
      throw Exception('Failed to add progress image: $e');
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('shop_orders').doc(orderId).update({
        'status': ShopOrderStatus.cancelled.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
