import 'package:cloud_firestore/cloud_firestore.dart';

/// Fabric Types
enum FabricType {
  cotton,
  silk,
  lace,
  ankara,
  denim,
  wool,
  polyester,
  linen,
  velvet,
  chiffon,
  other,
}

/// Model for Fabric Listing
class Fabric {
  final String id;
  final String sellerId;
  final String sellerName;
  final FabricType fabricType;
  final String color;
  final String pattern;
  final List<String> imageUrls; // Instagram-style gallery
  final double pricePerYard; // Per yard/meter
  final int quantityAvailable;
  final double fabricWidth; // In inches/cm
  final String weight; // Light, medium, heavy
  final String texture; // Smooth, rough, etc.
  final String careInstructions; // Washing, ironing guidelines
  final List<String> tags; // For easy searching
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isOutOfStock;
  final int? lowStockThreshold; // Alert when stock goes below this

  Fabric({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.fabricType,
    required this.color,
    required this.pattern,
    required this.imageUrls,
    required this.pricePerYard,
    required this.quantityAvailable,
    required this.fabricWidth,
    required this.weight,
    required this.texture,
    required this.careInstructions,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    this.isOutOfStock = false,
    this.lowStockThreshold = 10,
  });

  /// Get fabric type as string
  String getFabricTypeString() {
    return fabricType.toString().split('.').last.toUpperCase();
  }

  /// Check if stock is low
  bool isLowStock() {
    return quantityAvailable <= (lowStockThreshold ?? 10);
  }

  /// Get stock status indicator
  String getStockStatus() {
    if (isOutOfStock || quantityAvailable == 0) return 'Out of Stock';
    if (isLowStock()) return 'Low Stock';
    return 'In Stock';
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'fabricType': fabricType.toString().split('.').last,
      'color': color,
      'pattern': pattern,
      'imageUrls': imageUrls,
      'pricePerYard': pricePerYard,
      'quantityAvailable': quantityAvailable,
      'fabricWidth': fabricWidth,
      'weight': weight,
      'texture': texture,
      'careInstructions': careInstructions,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isOutOfStock': isOutOfStock,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  /// Create from Firestore document
  factory Fabric.fromMap(Map<String, dynamic> map, String documentId) {
    return Fabric(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      fabricType: _fabricTypeFromString(map['fabricType'] ?? 'cotton'),
      color: map['color'] ?? '',
      pattern: map['pattern'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      pricePerYard: (map['pricePerYard'] ?? 0).toDouble(),
      quantityAvailable: map['quantityAvailable'] ?? 0,
      fabricWidth: (map['fabricWidth'] ?? 0).toDouble(),
      weight: map['weight'] ?? '',
      texture: map['texture'] ?? '',
      careInstructions: map['careInstructions'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isOutOfStock: map['isOutOfStock'] ?? false,
      lowStockThreshold: map['lowStockThreshold'] ?? 10,
    );
  }

  /// Helper to convert string to FabricType
  static FabricType _fabricTypeFromString(String value) {
    return FabricType.values.firstWhere(
      (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => FabricType.other,
    );
  }

  /// Create a copy with modified fields
  Fabric copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    FabricType? fabricType,
    String? color,
    String? pattern,
    List<String>? imageUrls,
    double? pricePerYard,
    int? quantityAvailable,
    double? fabricWidth,
    String? weight,
    String? texture,
    String? careInstructions,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOutOfStock,
    int? lowStockThreshold,
  }) {
    return Fabric(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      fabricType: fabricType ?? this.fabricType,
      color: color ?? this.color,
      pattern: pattern ?? this.pattern,
      imageUrls: imageUrls ?? this.imageUrls,
      pricePerYard: pricePerYard ?? this.pricePerYard,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      fabricWidth: fabricWidth ?? this.fabricWidth,
      weight: weight ?? this.weight,
      texture: texture ?? this.texture,
      careInstructions: careInstructions ?? this.careInstructions,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
