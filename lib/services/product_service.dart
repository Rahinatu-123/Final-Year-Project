import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add new product to shop
  Future<String> addProduct(Product product) async {
    try {
      final docRef = await _firestore
          .collection('products')
          .add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Update product details
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product from shop
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Get all products from a specific seller
  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller products: $e');
    }
  }

  /// Get single product details
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Stream of seller's products (real-time updates)
  Stream<List<Product>> getSellerProductsStream(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  /// Get all products (for explore/shop page)
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Stream of all products (real-time updates)
  Stream<List<Product>> getAllProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  /// Get products filtered by type (clothes or fabric)
  Future<List<Product>> getProductsByType(ProductType type) async {
    try {
      final typeString = type.toString().split('.').last;
      final snapshot = await _firestore
          .collection('products')
          .where('type', isEqualTo: typeString)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by type: $e');
    }
  }

  /// Stream of products filtered by type
  Stream<List<Product>> getProductsByTypeStream(ProductType type) {
    final typeString = type.toString().split('.').last;
    return _firestore
        .collection('products')
        .where('type', isEqualTo: typeString)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  /// Get products filtered by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Search products by name or tags
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      final allProducts = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      // Simple client-side filtering
      final lowerQuery = query.toLowerCase();
      return allProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(lowerQuery) ||
                product.description.toLowerCase().contains(lowerQuery) ||
                product.tags.any(
                  (tag) => tag.toLowerCase().contains(lowerQuery),
                ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Toggle product sold out status
  Future<void> toggleSoldOut(String productId, bool isSoldOut) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isSoldOut': isSoldOut,
      });
    } catch (e) {
      throw Exception('Failed to toggle sold out status: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
