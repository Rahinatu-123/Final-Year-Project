import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomOrderStatus { active, delivered, cancelled }

enum DeliveryUrgency { green, yellow, red }

class CustomOrder {
  final String id;
  final String tailorId;
  final String clientName;
  final String? clientId; // null if manually added
  final String style;
  final String? styleImageUrl;
  final double basePrice;
  final String measurements; // JSON or text format
  final int daysToDeliver;
  final CustomOrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  CustomOrder({
    required this.id,
    required this.tailorId,
    required this.clientName,
    this.clientId,
    required this.style,
    this.styleImageUrl,
    required this.basePrice,
    required this.measurements,
    required this.daysToDeliver,
    this.status = CustomOrderStatus.active,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
  });

  /// Calculate days remaining until delivery
  int daysRemaining() {
    if (status == CustomOrderStatus.delivered) return 0;
    final now = DateTime.now();
    final deadline = dueDate ?? createdAt.add(Duration(days: daysToDeliver));
    final difference = deadline.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Get timeline urgency based on deadline proximity
  DeliveryUrgency getDeliveryUrgency() {
    if (status == CustomOrderStatus.delivered) return DeliveryUrgency.green;

    final remaining = daysRemaining();
    final totalDays = daysToDeliver;

    if (totalDays == 0) return DeliveryUrgency.red;

    final percentageElapsed = ((totalDays - remaining) / totalDays) * 100;

    if (percentageElapsed < 33) return DeliveryUrgency.green;
    if (percentageElapsed < 66) return DeliveryUrgency.yellow;
    return DeliveryUrgency.red;
  }

  /// Get color for urgency
  String getUrgencyColor() {
    switch (getDeliveryUrgency()) {
      case DeliveryUrgency.green:
        return '#2D6A4F';
      case DeliveryUrgency.yellow:
        return '#E8A855';
      case DeliveryUrgency.red:
        return '#BA1A1A';
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'clientName': clientName,
      'clientId': clientId,
      'style': style,
      'styleImageUrl': styleImageUrl,
      'basePrice': basePrice,
      'measurements': measurements,
      'daysToDeliver': daysToDeliver,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }

  /// Create from Firestore document
  factory CustomOrder.fromMap(Map<String, dynamic> map, String docId) {
    return CustomOrder(
      id: docId,
      tailorId: map['tailorId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientId: map['clientId'],
      style: map['style'] ?? '',
      styleImageUrl: map['styleImageUrl'],
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      measurements: map['measurements'] ?? '',
      daysToDeliver: map['daysToDeliver'] ?? 7,
      status: (map['status'] ?? 'active') == 'delivered'
          ? CustomOrderStatus.delivered
          : (map['status'] == 'cancelled'
                ? CustomOrderStatus.cancelled
                : CustomOrderStatus.active),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Create a copy with modified fields
  CustomOrder copyWith({
    String? id,
    String? tailorId,
    String? clientName,
    String? clientId,
    String? style,
    String? styleImageUrl,
    double? basePrice,
    String? measurements,
    int? daysToDeliver,
    CustomOrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
  }) {
    return CustomOrder(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      clientName: clientName ?? this.clientName,
      clientId: clientId ?? this.clientId,
      style: style ?? this.style,
      styleImageUrl: styleImageUrl ?? this.styleImageUrl,
      basePrice: basePrice ?? this.basePrice,
      measurements: measurements ?? this.measurements,
      daysToDeliver: daysToDeliver ?? this.daysToDeliver,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
