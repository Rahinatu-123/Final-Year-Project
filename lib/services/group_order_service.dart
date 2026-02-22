import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_order.dart';

class GroupOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _groupsCollection = 'group_orders';

  // Delete a group (only creator can delete)
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Check if group should be closed (deadline passed and members <= 2)
  bool shouldAutoCloseGroup(GroupOrder group) {
    final now = DateTime.now();
    return group.deadline.isBefore(now) && group.members.length <= 2;
  }

  // Update group status to closed
  Future<void> closeGroup(String groupId) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'status': 'closed',
      });
    } catch (e) {
      throw Exception('Failed to close group: $e');
    }
  }

  // Create a new group
  Future<String> createGroup(GroupOrder group) async {
    try {
      final docRef = await _firestore.collection(_groupsCollection).add({
        'name': group.name,
        'type': group.type.toString().split('.').last,
        'createdById': group.createdById,
        'createdByName': group.createdByName,
        'professionalId': group.professionalId,
        'professionalName': group.professionalName,
        'professionalImage': group.professionalImage,
        'description': group.description,
        'discountPercentage': group.discountPercentage,
        'maxParticipants': group.maxParticipants,
        'members': group.members.map((m) => m.toMap()).toList(),
        'status': 'open',
        'createdAt': DateTime.now(),
        'deadline': group.deadline,
        'image': group.image,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Get all groups
  Stream<List<GroupOrder>> getAllGroups(GroupOrderType type) {
    return _firestore
        .collection(_groupsCollection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupOrder.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get single group
  Future<GroupOrder?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .get();
      if (doc.exists) {
        return GroupOrder.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch group: $e');
    }
  }

  // Join a group
  Future<void> joinGroup({
    required String groupId,
    required String userId,
    required String userName,
    required String userImage,
    required String orderDescription,
  }) async {
    try {
      // Check if group should be auto-closed
      final group = await getGroupById(groupId);
      if (group != null && shouldAutoCloseGroup(group)) {
        await closeGroup(groupId);
        throw Exception(
          'This group has been closed due to insufficient members at deadline.',
        );
      }

      if (group != null && group.isFull) {
        throw Exception('This group is full. You cannot join.');
      }

      final member = GroupOrderMember(
        userId: userId,
        userName: userName,
        userImage: userImage,
        orderDescription: orderDescription,
        basePrice: null,
        joinedAt: DateTime.now(),
        isPriced: false,
      );

      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      // Check if group is now full
      final updatedGroup = await getGroupById(groupId);
      if (updatedGroup != null && updatedGroup.isFull) {
        await _firestore.collection(_groupsCollection).doc(groupId).update({
          'status': 'full',
        });
      }

      // Add system message
      await addMessage(
        groupId: groupId,
        senderId: 'system',
        senderName: 'System',
        senderImage: '',
        message: '$userName joined the group',
        isSystemMessage: true,
      );
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  // Set price for a member (tailor/seller only)
  Future<void> setPriceForMember({
    required String groupId,
    required String memberId,
    required double basePrice,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) throw Exception('Group not found');

      final updatedMembers = group.members.map((member) {
        if (member.userId == memberId) {
          return GroupOrderMember(
            userId: member.userId,
            userName: member.userName,
            userImage: member.userImage,
            orderDescription: member.orderDescription,
            basePrice: basePrice,
            joinedAt: member.joinedAt,
            isPriced: true,
          );
        }
        return member;
      }).toList();

      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });

      // Add system message
      final memberName = group.members
          .firstWhere((m) => m.userId == memberId)
          .userName;
      await addMessage(
        groupId: groupId,
        senderId: 'system',
        senderName: 'System',
        senderImage: '',
        message: 'Price set for $memberName: GH₵$basePrice',
        isSystemMessage: true,
      );
    } catch (e) {
      throw Exception('Failed to set price: $e');
    }
  }

  // Add message to group chat
  Future<void> addMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String message,
    bool isSystemMessage = false,
  }) async {
    try {
      await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'senderImage': senderImage,
            'message': message,
            'sentAt': DateTime.now(),
            'isSystemMessage': isSystemMessage,
          });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get group messages stream
  Stream<List<GroupMessage>> getGroupMessages(String groupId) {
    return _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupMessage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get user's groups
  Stream<List<GroupOrder>> getUserGroups(String userId, GroupOrderType type) {
    return _firestore
        .collection(_groupsCollection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupOrder.fromMap(doc.data(), doc.id))
              .where(
                (group) =>
                    group.members.any((m) => m.userId == userId) ||
                    group.createdById == userId ||
                    group.professionalId == userId,
              )
              .toList();
        });
  }

  // Update group status
  Future<void> updateGroupStatus({
    required String groupId,
    required String status,
  }) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
