import 'package:cloud_firestore/cloud_firestore.dart';

/// Enumeration for order status
enum OrderStatus { pending, completed }

/// Enumeration for timeline urgency colors
enum TimelineUrgency { green, yellow, red }

/// Model for order variants (color, size options)
class OrderVariant {
  final String color;
  final String size;
  final String? notes;

  OrderVariant({required this.color, required this.size, this.notes});

  Map<String, dynamic> toMap() {
    return {'color': color, 'size': size, 'notes': notes};
  }

  factory OrderVariant.fromMap(Map<String, dynamic> map) {
    return OrderVariant(
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      notes: map['notes'],
    );
  }
}

/// Main Order Model
class Order {
  final String id;
  final String tailorId;
  final String clientId;
  final String clientName;
  final String style; // Type of clothing (dress, suit, shirt, etc.)
  final String measurements; // JSON or text format of measurements
  final List<OrderVariant> variants;
  final String? referenceImageUrl; // URL to reference image
  final int daysEstimate; // Number of days for completion
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? additionalNotes;
  final List<String>? tags; // Fabric type, style category, etc.
  final Map<String, dynamic>?
  customMeasurements; // Additional measurement details

  Order({
    required this.id,
    required this.tailorId,
    required this.clientId,
    required this.clientName,
    required this.style,
    required this.measurements,
    required this.variants,
    required this.daysEstimate,
    this.referenceImageUrl,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.additionalNotes,
    this.tags,
    this.customMeasurements,
  });

  /// Get timeline urgency based on remaining days
  TimelineUrgency getTimelineUrgency() {
    final remainingDays = daysRemaining();
    if (remainingDays >= 7) return TimelineUrgency.green;
    if (remainingDays >= 3) return TimelineUrgency.yellow;
    return TimelineUrgency.red;
  }

  /// Calculate remaining days
  int daysRemaining() {
    if (status == OrderStatus.completed) return 0;
    final now = DateTime.now();
    final deadline = createdAt.add(Duration(days: daysEstimate));
    final difference = deadline.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Get urgency color
  String getUrgencyColor() {
    switch (getTimelineUrgency()) {
      case TimelineUrgency.green:
        return '#2D6A4F'; // Success green
      case TimelineUrgency.yellow:
        return '#E8A855'; // Warning yellow/orange
      case TimelineUrgency.red:
        return '#BA1A1A'; // Error red
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tailorId': tailorId,
      'clientId': clientId,
      'clientName': clientName,
      'style': style,
      'measurements': measurements,
      'variants': variants.map((v) => v.toMap()).toList(),
      'referenceImageUrl': referenceImageUrl,
      'daysEstimate': daysEstimate,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'additionalNotes': additionalNotes,
      'tags': tags ?? [],
      'customMeasurements': customMeasurements ?? {},
    };
  }

  /// Create from Firestore document
  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      tailorId: map['tailorId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      style: map['style'] ?? '',
      measurements: map['measurements'] ?? '',
      variants:
          (map['variants'] as List<dynamic>?)
              ?.map((v) => OrderVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      referenceImageUrl: map['referenceImageUrl'],
      daysEstimate: map['daysEstimate'] ?? 7,
      status: (map['status'] ?? 'pending') == 'completed'
          ? OrderStatus.completed
          : OrderStatus.pending,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      additionalNotes: map['additionalNotes'],
      tags: List<String>.from(map['tags'] as List? ?? []),
      customMeasurements: map['customMeasurements'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with modified fields
  Order copyWith({
    String? id,
    String? tailorId,
    String? clientId,
    String? clientName,
    String? style,
    String? measurements,
    List<OrderVariant>? variants,
    String? referenceImageUrl,
    int? daysEstimate,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? additionalNotes,
    List<String>? tags,
    Map<String, dynamic>? customMeasurements,
  }) {
    return Order(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      style: style ?? this.style,
      measurements: measurements ?? this.measurements,
      variants: variants ?? this.variants,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
      daysEstimate: daysEstimate ?? this.daysEstimate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      tags: tags ?? this.tags,
      customMeasurements: customMeasurements ?? this.customMeasurements,
    );
  }
}
