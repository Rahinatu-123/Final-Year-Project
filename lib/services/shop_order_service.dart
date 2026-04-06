import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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

  /// Get customer-visible orders, including linked custom orders.
  Stream<List<ShopOrder>> getCustomerOrdersIncludingCustomStream(
    String customerId,
  ) {
    if (customerId.isEmpty) {
      return Stream.value(const <ShopOrder>[]);
    }

    final controller = StreamController<List<ShopOrder>>();
    var shopOrders = <ShopOrder>[];
    var customOrders = <ShopOrder>[];

    void emitCombined() {
      final merged = <String, ShopOrder>{
        for (final order in customOrders) order.id: order,
      };

      for (final order in shopOrders) {
        merged[order.id] = order;
      }

      final list = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!controller.isClosed) {
        controller.add(list);
      }
    }

    final shopSub = _firestore
        .collection('shop_orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen(
          (snapshot) {
            shopOrders = snapshot.docs
                .map((doc) => ShopOrder.fromMap(doc.data(), doc.id))
                .toList();
            emitCombined();
          },
          onError: (error) {
            if (!controller.isClosed) controller.addError(error);
          },
        );

    final customSub = _firestore
        .collection('custom_orders')
        .where('clientUserId', isEqualTo: customerId)
        .snapshots()
        .listen(
          (snapshot) {
            customOrders = snapshot.docs
                .map(
                  (doc) => _customOrderToShopOrder(
                    doc.id,
                    doc.data(),
                    customerId,
                  ),
                )
                .toList();

            emitCombined();
          },
          onError: (error) {
            if (!controller.isClosed) controller.addError(error);
          },
        );

    controller.onCancel = () async {
      await shopSub.cancel();
      await customSub.cancel();
    };

    return controller.stream;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  ShopOrderStatus _mapCustomOrderStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    switch (normalized) {
      case 'completed':
        return ShopOrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return ShopOrderStatus.cancelled;
      case 'ready':
        return ShopOrderStatus.ready;
      case 'inprogress':
      case 'in_progress':
      case 'active':
        return ShopOrderStatus.inProgress;
      case 'confirmed':
        return ShopOrderStatus.confirmed;
      default:
        return ShopOrderStatus.pending;
    }
  }

  /// Get a single order
  Future<ShopOrder?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('shop_orders').doc(orderId).get();
      if (doc.exists) {
        return ShopOrder.fromMap(doc.data()!, orderId);
      }

      // Fallback for linked client orders stored in custom_orders.
      final customDoc = await _firestore
          .collection('custom_orders')
          .doc(orderId)
          .get();

      if (customDoc.exists) {
        final customData = customDoc.data()!;
        final customerId = (customData['clientUserId'] ?? '').toString();
        return _customOrderToShopOrder(orderId, customData, customerId);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  ShopOrder _customOrderToShopOrder(
    String orderId,
    Map<String, dynamic> data,
    String customerId,
  ) {
    final imageUrl = (data['styleImageUrl'] ?? '').toString();
    final status = _mapCustomOrderStatus((data['status'] ?? 'pending').toString());
    final createdAt = _toDateTime(data['createdAt']) ?? DateTime.now();
    final updatedAt = _toDateTime(data['updatedAt']);
    final completedAt = _toDateTime(data['completedAt']);
    final dueDate = _toDateTime(data['dueDate']);

    DateTime? confirmedAt;
    DateTime? startedAt;

    if (status == ShopOrderStatus.confirmed ||
        status == ShopOrderStatus.inProgress ||
        status == ShopOrderStatus.ready ||
        status == ShopOrderStatus.completed) {
      confirmedAt = createdAt;
    }

    if (status == ShopOrderStatus.inProgress ||
        status == ShopOrderStatus.ready ||
        status == ShopOrderStatus.completed) {
      startedAt = updatedAt ?? createdAt;
    }

    return ShopOrder(
      id: orderId,
      customerId: customerId,
      tailorId: (data['tailorId'] ?? '').toString(),
      productId: 'custom_$orderId',
      productName: (data['style'] ?? 'Custom Order').toString(),
      productImages: imageUrl.isNotEmpty ? [imageUrl] : const [],
      productPrice: ((data['basePrice'] ?? 0) as num).toDouble(),
      quantity: 1,
      customizations: (data['measurements'] ?? '').toString().trim().isEmpty
          ? null
          : (data['measurements'] ?? '').toString(),
      status: status,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      estimatedDelivery: dueDate,
      notes: 'Custom order from tailor',
    );
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
