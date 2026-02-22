import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a tailor's manually added client
class TailorClient {
  final String id;
  final String tailorId;
  final String name;
  final String? profileImageUrl;
  final DateTime createdAt;

  TailorClient({
    required this.id,
    required this.tailorId,
    required this.name,
    this.profileImageUrl,
    required this.createdAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory TailorClient.fromMap(Map<String, dynamic> map, String docId) {
    return TailorClient(
      id: docId,
      tailorId: map['tailorId'] ?? '',
      name: map['name'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
