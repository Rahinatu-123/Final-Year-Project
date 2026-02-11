import 'package:cloud_firestore/cloud_firestore.dart';

/// Business hours model
class BusinessHours {
  final String dayOfWeek; // Monday-Sunday
  final String openTime; // HH:mm format
  final String closeTime; // HH:mm format
  final bool isOpen;

  BusinessHours({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.isOpen = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'openTime': openTime,
      'closeTime': closeTime,
      'isOpen': isOpen,
    };
  }

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(
      dayOfWeek: map['dayOfWeek'] ?? '',
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '17:00',
      isOpen: map['isOpen'] ?? true,
    );
  }
}

/// Tailor/Business Profile Model
class TailorProfile {
  final String uid;
  final String businessName;
  final String? businessDescription;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final String? phoneNumber;
  final String? email;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? instagramHandle;
  final List<String> portfolioImageUrls; // Showcase of work
  final List<BusinessHours> businessHours;
  final double? rating; // Average rating from clients
  final int? totalOrders;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final String? bio;
  final List<String>? specialties; // Dress, suit, shirt, etc.

  TailorProfile({
    required this.uid,
    required this.businessName,
    this.businessDescription,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.phoneNumber,
    this.email,
    this.location,
    this.latitude,
    this.longitude,
    this.instagramHandle,
    this.portfolioImageUrls = const [],
    this.businessHours = const [],
    this.rating,
    this.totalOrders,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.bio,
    this.specialties,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'phoneNumber': phoneNumber,
      'email': email,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'instagramHandle': instagramHandle,
      'portfolioImageUrls': portfolioImageUrls,
      'businessHours': businessHours.map((h) => h.toMap()).toList(),
      'rating': rating,
      'totalOrders': totalOrders,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'bio': bio,
      'specialties': specialties ?? [],
    };
  }

  factory TailorProfile.fromMap(Map<String, dynamic> map, String uid) {
    return TailorProfile(
      uid: uid,
      businessName: map['businessName'] ?? '',
      businessDescription: map['businessDescription'],
      profileImageUrl: map['profileImageUrl'],
      bannerImageUrl: map['bannerImageUrl'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      location: map['location'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      instagramHandle: map['instagramHandle'],
      portfolioImageUrls: List<String>.from(
        map['portfolioImageUrls'] as List? ?? [],
      ),
      businessHours:
          (map['businessHours'] as List<dynamic>?)
              ?.map((h) => BusinessHours.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      rating: (map['rating'] as num?)?.toDouble(),
      totalOrders: map['totalOrders'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      bio: map['bio'],
      specialties: List<String>.from(map['specialties'] as List? ?? []),
    );
  }

  TailorProfile copyWith({
    String? uid,
    String? businessName,
    String? businessDescription,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? phoneNumber,
    String? email,
    String? location,
    double? latitude,
    double? longitude,
    String? instagramHandle,
    List<String>? portfolioImageUrls,
    List<BusinessHours>? businessHours,
    double? rating,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? bio,
    List<String>? specialties,
  }) {
    return TailorProfile(
      uid: uid ?? this.uid,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      portfolioImageUrls: portfolioImageUrls ?? this.portfolioImageUrls,
      businessHours: businessHours ?? this.businessHours,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
    );
  }
}
