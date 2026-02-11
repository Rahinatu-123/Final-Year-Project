import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Fabric Seller Shop Profile
class FabricSeller {
  final String id;
  final String userId;
  final String shopName;
  final String description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String email;
  final String phoneNumber;
  final String location;
  final List<String> deliveryAreas;
  final String businessHours;
  final List<String> paymentMethods;
  final String returnExchangePolicy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? averageRating;
  final int? totalReviews;
  final int? totalSales;
  final List<String>? certifications;
  final bool isVerified;
  final String? bankDetails;

  FabricSeller({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.description,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.deliveryAreas,
    required this.businessHours,
    required this.paymentMethods,
    required this.returnExchangePolicy,
    required this.createdAt,
    this.logoUrl,
    this.coverImageUrl,
    this.updatedAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalSales = 0,
    this.certifications,
    this.isVerified = false,
    this.bankDetails,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'shopName': shopName,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'deliveryAreas': deliveryAreas,
      'businessHours': businessHours,
      'paymentMethods': paymentMethods,
      'returnExchangePolicy': returnExchangePolicy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalSales': totalSales,
      'certifications': certifications,
      'isVerified': isVerified,
      'bankDetails': bankDetails,
    };
  }

  /// Create from Firestore document
  factory FabricSeller.fromMap(Map<String, dynamic> map, String documentId) {
    return FabricSeller(
      id: documentId,
      userId: map['userId'] ?? '',
      shopName: map['shopName'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      coverImageUrl: map['coverImageUrl'],
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      location: map['location'] ?? '',
      deliveryAreas: List<String>.from(map['deliveryAreas'] ?? []),
      businessHours: map['businessHours'] ?? '',
      paymentMethods: List<String>.from(map['paymentMethods'] ?? []),
      returnExchangePolicy: map['returnExchangePolicy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      totalSales: map['totalSales'] ?? 0,
      certifications: List<String>.from(map['certifications'] ?? []),
      isVerified: map['isVerified'] ?? false,
      bankDetails: map['bankDetails'],
    );
  }

  /// Create a copy with modified fields
  FabricSeller copyWith({
    String? id,
    String? userId,
    String? shopName,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? email,
    String? phoneNumber,
    String? location,
    List<String>? deliveryAreas,
    String? businessHours,
    List<String>? paymentMethods,
    String? returnExchangePolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? averageRating,
    int? totalReviews,
    int? totalSales,
    List<String>? certifications,
    bool? isVerified,
    String? bankDetails,
  }) {
    return FabricSeller(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      deliveryAreas: deliveryAreas ?? this.deliveryAreas,
      businessHours: businessHours ?? this.businessHours,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      returnExchangePolicy: returnExchangePolicy ?? this.returnExchangePolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSales: totalSales ?? this.totalSales,
      certifications: certifications ?? this.certifications,
      isVerified: isVerified ?? this.isVerified,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}
