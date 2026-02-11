import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fabric.dart';
import '../models/fabric_order.dart';
import '../models/fabric_seller.dart';

class FabricSellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FABRIC OPERATIONS ====================

  /// Add new fabric to seller's catalog
  Future<String> addFabric(Fabric fabric) async {
    try {
      final docRef = await _firestore.collection('fabrics').add(fabric.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add fabric: $e');
    }
  }

  /// Update fabric details
  Future<void> updateFabric(
    String fabricId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _firestore.collection('fabrics').doc(fabricId).update(updates);
    } catch (e) {
      throw Exception('Failed to update fabric: $e');
    }
  }

  /// Delete fabric from catalog
  Future<void> deleteFabric(String fabricId) async {
    try {
      await _firestore.collection('fabrics').doc(fabricId).delete();
    } catch (e) {
      throw Exception('Failed to delete fabric: $e');
    }
  }

  /// Get all fabrics from a specific seller
  Future<List<Fabric>> getSellerFabrics(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('fabrics')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Fabric.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller fabrics: $e');
    }
  }

  /// Get single fabric details
  Future<Fabric?> getFabricDetails(String fabricId) async {
    try {
      final doc = await _firestore.collection('fabrics').doc(fabricId).get();
      if (doc.exists) {
        return Fabric.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch fabric details: $e');
    }
  }

  /// Get low stock fabrics for seller
  Future<List<Fabric>> getLowStockFabrics(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('fabrics')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final fabrics = snapshot.docs
          .map((doc) => Fabric.fromMap(doc.data(), doc.id))
          .toList();

      return fabrics.where((fabric) => fabric.isLowStock()).toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock fabrics: $e');
    }
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create order from chat
  Future<String> createFabricOrder(FabricOrder order) async {
    try {
      final docRef = await _firestore
          .collection('fabric_orders')
          .add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    FabricOrderStatus status,
  ) async {
    try {
      await _firestore.collection('fabric_orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Get all orders for seller
  Future<List<FabricOrder>> getSellerOrders(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('fabric_orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FabricOrder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller orders: $e');
    }
  }

  /// Get orders by status
  Future<List<FabricOrder>> getOrdersByStatus(
    String sellerId,
    FabricOrderStatus status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('fabric_orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FabricOrder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  /// Get single order details
  Future<FabricOrder?> getOrderDetails(String orderId) async {
    try {
      final doc = await _firestore
          .collection('fabric_orders')
          .doc(orderId)
          .get();
      if (doc.exists) {
        return FabricOrder.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  /// Add note to order
  Future<void> addOrderNote(String orderId, String note) async {
    try {
      await _firestore.collection('fabric_orders').doc(orderId).update({
        'notes': FieldValue.arrayUnion([note]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to add order note: $e');
    }
  }

  /// Add photos to order
  Future<void> addOrderPhotos(String orderId, List<String> photoUrls) async {
    try {
      await _firestore.collection('fabric_orders').doc(orderId).update({
        'photosUrl': FieldValue.arrayUnion(photoUrls),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to add order photos: $e');
    }
  }

  // ==================== SELLER PROFILE OPERATIONS ====================

  /// Create or update seller profile
  Future<String> saveFabricSellerProfile(FabricSeller seller) async {
    try {
      await _firestore
          .collection('fabric_sellers')
          .doc(seller.id)
          .set(seller.toMap(), SetOptions(merge: true));
      return seller.id;
    } catch (e) {
      throw Exception('Failed to save seller profile: $e');
    }
  }

  /// Get seller profile
  Future<FabricSeller?> getSellerProfile(String sellerId) async {
    try {
      final doc = await _firestore
          .collection('fabric_sellers')
          .doc(sellerId)
          .get();

      if (doc.exists) {
        return FabricSeller.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch seller profile: $e');
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Get sales overview for seller
  Future<Map<String, dynamic>> getSalesOverview(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('fabric_orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double totalRevenue = 0;
      for (var doc in snapshot.docs) {
        totalRevenue += (doc['totalPrice'] ?? 0).toDouble();
      }

      return {
        'totalSales': snapshot.docs.length,
        'totalRevenue': totalRevenue,
        'averageOrderValue': snapshot.docs.isEmpty
            ? 0
            : totalRevenue / snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch sales overview: $e');
    }
  }

  /// Get best selling fabrics
  Future<List<Map<String, dynamic>>> getBestSellingFabrics(
    String sellerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('fabric_orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'delivered')
          .get();

      Map<String, int> fabricCounts = {};
      Map<String, Map<String, dynamic>> fabricDetails = {};

      for (var doc in snapshot.docs) {
        final order = FabricOrder.fromMap(doc.data(), doc.id);
        for (var item in order.items) {
          fabricCounts[item.fabricId] = (fabricCounts[item.fabricId] ?? 0) + 1;
          if (!fabricDetails.containsKey(item.fabricId)) {
            fabricDetails[item.fabricId] = {
              'name': item.fabricName,
              'color': item.color,
              'count': 0,
              'revenue': 0.0,
            };
          }
          fabricDetails[item.fabricId]!['count'] =
              (fabricDetails[item.fabricId]!['count'] as int) + 1;
          fabricDetails[item.fabricId]!['revenue'] =
              (fabricDetails[item.fabricId]!['revenue'] as double) +
              item.subtotal;
        }
      }

      final sorted = fabricCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(10)
          .map(
            (entry) => {
              'fabricId': entry.key,
              'count': entry.value,
              ...?fabricDetails[entry.key],
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch best selling fabrics: $e');
    }
  }

  /// Stream seller orders for real-time updates
  Stream<List<FabricOrder>> streamSellerOrders(String sellerId) {
    try {
      return _firestore
          .collection('fabric_orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FabricOrder.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to stream seller orders: $e');
    }
  }
}
