import 'package:cloud_firestore/cloud_firestore.dart';

/// Client Model
class Client {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? address;
  final List<String>
  preferredTailorIds; // List of tailor IDs client has worked with
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isActive;

  Client({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.address,
    this.preferredTailorIds = const [],
    required this.createdAt,
    this.lastActiveAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'preferredTailorIds': preferredTailorIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
      'isActive': isActive,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map, String uid) {
    return Client(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      address: map['address'],
      preferredTailorIds: List<String>.from(
        map['preferredTailorIds'] as List? ?? [],
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Client copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? address,
    List<String>? preferredTailorIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return Client(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      preferredTailorIds: preferredTailorIds ?? this.preferredTailorIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
