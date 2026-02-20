import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Type (what kind of item is being sold)
enum ProductType {
  clothes, // For finished garments from tailors
  fabric, // For fabrics from fabric sellers
}

/// Model for Shop Product (Finished garments or fabric for sale)
class Product {
  final String id;
  final String sellerId; // Tailor/Fabric seller ID
  final String sellerName; // Display name of seller
  final ProductType type; // Whether it's clothes or fabric
  final String name; // Product name
  final String description; // Product description
  final List<String> imageUrls; // Product images
  final double price; // Original price
  final double? discountedPrice; // Price after discount (if any)
  final double? discountPercent; // Discount percentage
  final bool isSoldOut; // Whether product is sold out
  final String? category; // Clothes/Fabric category
  final String? color; // Color of item
  final String? size; // Size (for clothes)
  final bool? isCustomizable; // Can be customized?
  final List<String> tags; // Tags for search
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.type,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.price,
    this.discountedPrice,
    this.discountPercent,
    required this.isSoldOut,
    this.category,
    this.color,
    this.size,
    this.isCustomizable,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert Product to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'price': price,
      'discountedPrice': discountedPrice,
      'discountPercent': discountPercent,
      'isSoldOut': isSoldOut,
      'category': category,
      'color': color,
      'size': size,
      'isCustomizable': isCustomizable,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create Product from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    ProductType typeEnum = ProductType.clothes;
    if (data['type'] == 'fabric') {
      typeEnum = ProductType.fabric;
    }

    return Product(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      type: typeEnum,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      discountedPrice: data['discountedPrice']?.toDouble(),
      discountPercent: data['discountPercent']?.toDouble(),
      isSoldOut: data['isSoldOut'] ?? false,
      category: data['category'],
      color: data['color'],
      size: data['size'],
      isCustomizable: data['isCustomizable'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create a copy with modified fields
  Product copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    ProductType? type,
    String? name,
    String? description,
    List<String>? imageUrls,
    double? price,
    double? discountedPrice,
    double? discountPercent,
    bool? isSoldOut,
    String? category,
    String? color,
    String? size,
    bool? isCustomizable,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      category: category ?? this.category,
      color: color ?? this.color,
      size: size ?? this.size,
      isCustomizable: isCustomizable ?? this.isCustomizable,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get final price (discounted or original)
  double getFinalPrice() {
    return discountedPrice ?? price;
  }

  /// Get discount amount
  double? getDiscountAmount() {
    if (discountedPrice != null) {
      return price - discountedPrice!;
    }
    return null;
  }
}
