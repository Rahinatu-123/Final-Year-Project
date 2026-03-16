import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupOrderType { sewing, fabric }

enum GroupOrderStatus { open, full, closed, inProgress, completed, cancelled }

class GroupOrderMember {
  final String userId;
  final String userName;
  final String userImage;
  final String orderDescription;
  final double? basePrice; // Set by tailor/seller
  final DateTime joinedAt;
  final bool isPriced;

  GroupOrderMember({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.orderDescription,
    this.basePrice,
    required this.joinedAt,
    this.isPriced = false,
  });

  double get discountedPrice {
    if (basePrice == null) return 0;
    return basePrice! * 0.9; // 10% discount
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'orderDescription': orderDescription,
      'basePrice': basePrice,
      'joinedAt': joinedAt,
      'isPriced': isPriced,
    };
  }

  factory GroupOrderMember.fromMap(Map<String, dynamic> map) {
    return GroupOrderMember(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      userImage: map['userImage'] ?? '',
      orderDescription: map['orderDescription'] ?? '',
      basePrice: map['basePrice']?.toDouble(),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPriced: map['isPriced'] ?? false,
    );
  }
}

class GroupOrder {
  final String id;
  final String name;
  final GroupOrderType type; // sewing or fabric
  final String createdById;
  final String createdByName;
  final String professionalId; // tailor or fabric seller
  final String professionalName;
  final String professionalImage;
  final String description;
  final double discountPercentage; // Fixed at 10%
  final int maxParticipants; // Fixed at 10
  final List<GroupOrderMember> members;
  final GroupOrderStatus status;
  final DateTime createdAt;
  final DateTime deadline;
  final String? image;

  GroupOrder({
    required this.id,
    required this.name,
    required this.type,
    required this.createdById,
    required this.createdByName,
    required this.professionalId,
    required this.professionalName,
    required this.professionalImage,
    required this.description,
    this.discountPercentage = 20.0,
    this.maxParticipants = 10,
    required this.members,
    required this.status,
    required this.createdAt,
    required this.deadline,
    this.image,
  });

  int get availableSpots => maxParticipants - members.length;
  bool get isFull => members.length >= maxParticipants;
  bool get isExpired => deadline.isBefore(DateTime.now());
  int get pricedMembersCount => members.where((m) => m.isPriced).length;

  GroupOrderStatus get effectiveStatus {
    if (status == GroupOrderStatus.completed ||
        status == GroupOrderStatus.cancelled ||
        status == GroupOrderStatus.inProgress) {
      return status;
    }

    if (status == GroupOrderStatus.closed || isExpired) {
      return GroupOrderStatus.closed;
    }

    if (isFull) {
      return GroupOrderStatus.full;
    }

    return GroupOrderStatus.open;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'createdById': createdById,
      'createdByName': createdByName,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'professionalImage': professionalImage,
      'description': description,
      'discountPercentage': discountPercentage,
      'maxParticipants': maxParticipants,
      'members': members.map((m) => m.toMap()).toList(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'deadline': deadline,
      'image': image,
    };
  }

  factory GroupOrder.fromMap(Map<String, dynamic> map, String docId) {
    final typeString = map['type'] ?? 'sewing';
    final statusString = map['status'] ?? 'open';

    return GroupOrder(
      id: docId,
      name: map['name'] ?? '',
      type: typeString == 'fabric'
          ? GroupOrderType.fabric
          : GroupOrderType.sewing,
      createdById: map['createdById'] ?? '',
      createdByName: map['createdByName'] ?? 'User',
      professionalId: map['professionalId'] ?? '',
      professionalName: map['professionalName'] ?? 'Professional',
      professionalImage: map['professionalImage'] ?? '',
      description: map['description'] ?? '',
      discountPercentage: (map['discountPercentage'] ?? 20.0).toDouble(),
      maxParticipants: map['maxParticipants'] ?? 10,
      members:
          (map['members'] as List?)
              ?.where((m) => m != null)
              .map((m) => GroupOrderMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(statusString),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline:
          (map['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      image: map['image'],
    );
  }

  static GroupOrderStatus _parseStatus(String status) {
    switch (status) {
      case 'full':
        return GroupOrderStatus.full;
      case 'closed':
        return GroupOrderStatus.closed;
      case 'inProgress':
        return GroupOrderStatus.inProgress;
      case 'completed':
        return GroupOrderStatus.completed;
      case 'cancelled':
        return GroupOrderStatus.cancelled;
      default:
        return GroupOrderStatus.open;
    }
  }
}

class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String message;
  final DateTime sentAt;
  final bool isSystemMessage;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.message,
    required this.sentAt,
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'message': message,
      'sentAt': sentAt,
      'isSystemMessage': isSystemMessage,
    };
  }

  factory GroupMessage.fromMap(Map<String, dynamic> map, String docId) {
    return GroupMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'User',
      senderImage: map['senderImage'] ?? '',
      message: map['message'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: map['isSystemMessage'] ?? false,
    );
  }
}
