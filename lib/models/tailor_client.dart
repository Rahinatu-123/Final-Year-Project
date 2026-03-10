import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a tailor's manually added client
class TailorClient {
  final String id;
  final String tailorId;
  final String name;
  final String? phone;
  final String? email;
  final String? nameKey;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastOrderAt;
  final DateTime? updatedAt;
  final int totalOrders;

  TailorClient({
    required this.id,
    required this.tailorId,
    required this.name,
    this.phone,
    this.email,
    this.nameKey,
    this.profileImageUrl,
    required this.createdAt,
    this.lastOrderAt,
    this.updatedAt,
    this.totalOrders = 0,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'name': name,
      'nameKey': nameKey,
      'phone': phone,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastOrderAt': lastOrderAt != null
          ? Timestamp.fromDate(lastOrderAt!)
          : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'totalOrders': totalOrders,
    };
  }

  /// Create from Firestore document
  factory TailorClient.fromMap(Map<String, dynamic> map, String docId) {
    return TailorClient(
      id: docId,
      tailorId: map['tailorId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      nameKey: map['nameKey'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastOrderAt: (map['lastOrderAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
    );
  }
}
