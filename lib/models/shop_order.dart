import 'package:cloud_firestore/cloud_firestore.dart';

/// Shop Order Status
enum ShopOrderStatus {
  pending,
  confirmed,
  inProgress,
  ready,
  completed,
  cancelled,
}

/// Shop Order Model - For ordering finished products from shop
class ShopOrder {
  final String id;
  final String customerId; // Customer who ordered
  final String tailorId; // Tailor/Seller ID
  final String productId; // Product being ordered
  final String productName;
  final List<String> productImages;
  final double productPrice;
  final double? discountedPrice;

  final int quantity;
  final String? color;
  final String? size;
  final String? customizations; // Customer notes/special requests

  final ShopOrderStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedDelivery;

  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingZipCode;

  final String? notes; // Customer notes
  final String? tailorNotes; // Tailor progress updates
  final List<String> progressImages; // Images uploaded by tailor

  ShopOrder({
    required this.id,
    required this.customerId,
    required this.tailorId,
    required this.productId,
    required this.productName,
    required this.productImages,
    required this.productPrice,
    this.discountedPrice,
    required this.quantity,
    this.color,
    this.size,
    this.customizations,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.estimatedDelivery,
    this.shippingAddress,
    this.shippingCity,
    this.shippingZipCode,
    this.notes,
    this.tailorNotes,
    this.progressImages = const [],
  });

  /// Get total price
  double getTotalPrice() {
    final unitPrice = discountedPrice ?? productPrice;
    return unitPrice * quantity;
  }

  /// Map to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'tailorId': tailorId,
      'productId': productId,
      'productName': productName,
      'productImages': productImages,
      'productPrice': productPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'color': color,
      'size': size,
      'customizations': customizations,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'shippingZipCode': shippingZipCode,
      'notes': notes,
      'tailorNotes': tailorNotes,
      'progressImages': progressImages,
    };
  }

  /// Create from Firestore
  factory ShopOrder.fromMap(Map<String, dynamic> map, String docId) {
    return ShopOrder(
      id: docId,
      customerId: map['customerId'] ?? '',
      tailorId: map['tailorId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImages: List<String>.from(map['productImages'] ?? []),
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      discountedPrice: map['discountedPrice']?.toDouble(),
      quantity: map['quantity'] ?? 1,
      color: map['color'],
      size: map['size'],
      customizations: map['customizations'],
      status: _parseStatus(map['status']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      estimatedDelivery: (map['estimatedDelivery'] as Timestamp?)?.toDate(),
      shippingAddress: map['shippingAddress'],
      shippingCity: map['shippingCity'],
      shippingZipCode: map['shippingZipCode'],
      notes: map['notes'],
      tailorNotes: map['tailorNotes'],
      progressImages: List<String>.from(map['progressImages'] ?? []),
    );
  }

  static ShopOrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return ShopOrderStatus.confirmed;
      case 'inProgress':
        return ShopOrderStatus.inProgress;
      case 'ready':
        return ShopOrderStatus.ready;
      case 'completed':
        return ShopOrderStatus.completed;
      case 'cancelled':
        return ShopOrderStatus.cancelled;
      default:
        return ShopOrderStatus.pending;
    }
  }

  /// Copy with
  ShopOrder copyWith({
    String? id,
    String? customerId,
    String? tailorId,
    String? productId,
    String? productName,
    List<String>? productImages,
    double? productPrice,
    double? discountedPrice,
    int? quantity,
    String? color,
    String? size,
    String? customizations,
    ShopOrderStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? estimatedDelivery,
    String? shippingAddress,
    String? shippingCity,
    String? shippingZipCode,
    String? notes,
    String? tailorNotes,
    List<String>? progressImages,
  }) {
    return ShopOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      tailorId: tailorId ?? this.tailorId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImages: productImages ?? this.productImages,
      productPrice: productPrice ?? this.productPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      color: color ?? this.color,
      size: size ?? this.size,
      customizations: customizations ?? this.customizations,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingZipCode: shippingZipCode ?? this.shippingZipCode,
      notes: notes ?? this.notes,
      tailorNotes: tailorNotes ?? this.tailorNotes,
      progressImages: progressImages ?? this.progressImages,
    );
  }
}
