import 'package:cloud_firestore/cloud_firestore.dart';

/// Fabric Order Status
enum FabricOrderStatus {
  pending,
  processing,
  readyForPickup,
  delivered,
  cancelled,
}

/// Timeline Urgency Colors
enum OrderUrgency { green, yellow, red }

/// Model for Fabric Order (In-Chat Order Creation)
class FabricOrder {
  final String id;
  final String sellerId;
  final String sellerName;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final List<FabricOrderItem> items; // List of fabric items being ordered
  final double totalPrice;
  final FabricOrderStatus status;
  final DateTime createdAt;
  final DateTime? expectedDeliveryDate;
  final String deliveryMethod; // 'pickup' or 'delivery'
  final String? deliveryAddress;
  final String? pickupLocation;
  final int? estimatedDays; // Days estimate for delivery
  final Map<String, dynamic>? paymentDetails;
  final String? paymentStatus; // 'paid', 'pending', 'partial'
  final List<String> notes; // Special instructions or updates
  final List<String>? photosUrl; // Evidence of fabric cut/prepared
  final String? receiptUrl;
  final DateTime? updatedAt;

  FabricOrder({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.deliveryMethod,
    this.expectedDeliveryDate,
    this.deliveryAddress,
    this.pickupLocation,
    this.estimatedDays,
    this.paymentDetails,
    this.paymentStatus = 'pending',
    this.notes = const [],
    this.photosUrl,
    this.receiptUrl,
    this.updatedAt,
  });

  /// Get order urgency based on age and status
  OrderUrgency getUrgency() {
    if (status == FabricOrderStatus.delivered ||
        status == FabricOrderStatus.cancelled) {
      return OrderUrgency.green;
    }

    final daysOld = DateTime.now().difference(createdAt).inDays;

    if (daysOld <= 2) return OrderUrgency.green;
    if (daysOld <= 5) return OrderUrgency.yellow;
    return OrderUrgency.red;
  }

  /// Get urgency color code
  String getUrgencyColor() {
    switch (getUrgency()) {
      case OrderUrgency.green:
        return '#2D6A4F'; // Success green
      case OrderUrgency.yellow:
        return '#E8A855'; // Warning yellow/orange
      case OrderUrgency.red:
        return '#BA1A1A'; // Error red
    }
  }

  /// Get status as string
  String getStatusString() {
    switch (status) {
      case FabricOrderStatus.pending:
        return 'Pending';
      case FabricOrderStatus.processing:
        return 'Processing';
      case FabricOrderStatus.readyForPickup:
        return 'Ready for Pickup/Delivery';
      case FabricOrderStatus.delivered:
        return 'Delivered/Completed';
      case FabricOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Calculate days remaining
  int daysRemaining() {
    if (status == FabricOrderStatus.delivered ||
        status == FabricOrderStatus.cancelled) {
      return 0;
    }

    if (expectedDeliveryDate == null && estimatedDays == null) return 0;

    final deadline =
        expectedDeliveryDate ??
        createdAt.add(Duration(days: estimatedDays ?? 0));
    final difference = deadline.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'expectedDeliveryDate': expectedDeliveryDate,
      'deliveryMethod': deliveryMethod,
      'deliveryAddress': deliveryAddress,
      'pickupLocation': pickupLocation,
      'estimatedDays': estimatedDays,
      'paymentDetails': paymentDetails,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'photosUrl': photosUrl,
      'receiptUrl': receiptUrl,
      'updatedAt': updatedAt,
    };
  }

  /// Create from Firestore document
  factory FabricOrder.fromMap(Map<String, dynamic> map, String documentId) {
    return FabricOrder(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      items: List<FabricOrderItem>.from(
        (map['items'] as List?)?.map((item) => FabricOrderItem.fromMap(item)) ??
            [],
      ),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: _statusFromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDeliveryDate: (map['expectedDeliveryDate'] as Timestamp?)
          ?.toDate(),
      deliveryMethod: map['deliveryMethod'] ?? 'pickup',
      deliveryAddress: map['deliveryAddress'],
      pickupLocation: map['pickupLocation'],
      estimatedDays: map['estimatedDays'],
      paymentDetails: map['paymentDetails'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
      notes: List<String>.from(map['notes'] ?? []),
      photosUrl: List<String>.from(map['photosUrl'] ?? []),
      receiptUrl: map['receiptUrl'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Helper to convert string to FabricOrderStatus
  static FabricOrderStatus _statusFromString(String value) {
    return FabricOrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => FabricOrderStatus.pending,
    );
  }

  /// Create a copy with modified fields
  FabricOrder copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    List<FabricOrderItem>? items,
    double? totalPrice,
    FabricOrderStatus? status,
    DateTime? createdAt,
    DateTime? expectedDeliveryDate,
    String? deliveryMethod,
    String? deliveryAddress,
    String? pickupLocation,
    int? estimatedDays,
    Map<String, dynamic>? paymentDetails,
    String? paymentStatus,
    List<String>? notes,
    List<String>? photosUrl,
    String? receiptUrl,
    DateTime? updatedAt,
  }) {
    return FabricOrder(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      photosUrl: photosUrl ?? this.photosUrl,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for items within a Fabric Order
class FabricOrderItem {
  final String fabricId;
  final String fabricName;
  final String fabricType;
  final String color;
  final double quantityYards; // Quantity in yards/meters
  final double pricePerYard;
  final double subtotal;
  final List<String> fabricImages;

  FabricOrderItem({
    required this.fabricId,
    required this.fabricName,
    required this.fabricType,
    required this.color,
    required this.quantityYards,
    required this.pricePerYard,
    required this.subtotal,
    required this.fabricImages,
  });

  Map<String, dynamic> toMap() {
    return {
      'fabricId': fabricId,
      'fabricName': fabricName,
      'fabricType': fabricType,
      'color': color,
      'quantityYards': quantityYards,
      'pricePerYard': pricePerYard,
      'subtotal': subtotal,
      'fabricImages': fabricImages,
    };
  }

  factory FabricOrderItem.fromMap(Map<String, dynamic> map) {
    return FabricOrderItem(
      fabricId: map['fabricId'] ?? '',
      fabricName: map['fabricName'] ?? '',
      fabricType: map['fabricType'] ?? '',
      color: map['color'] ?? '',
      quantityYards: (map['quantityYards'] ?? 0).toDouble(),
      pricePerYard: (map['pricePerYard'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      fabricImages: List<String>.from(map['fabricImages'] ?? []),
    );
  }
}
