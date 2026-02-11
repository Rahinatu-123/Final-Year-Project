import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a notification
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? orderId;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.orderId,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'orderId': orderId,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      orderId: map['orderId'],
      type: _parseNotificationType(map['type']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'orderCreated':
        return NotificationType.orderCreated;
      case 'orderUpdated':
        return NotificationType.orderUpdated;
      case 'deadlineReminder':
        return NotificationType.deadlineReminder;
      case 'orderCompleted':
        return NotificationType.orderCompleted;
      case 'chat':
        return NotificationType.chat;
      default:
        return NotificationType.general;
    }
  }
}

/// Enumeration for notification types
enum NotificationType {
  orderCreated,
  orderUpdated,
  deadlineReminder,
  orderCompleted,
  chat,
  general,
}

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String notificationsCollection = 'notifications';

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
  }) async {
    try {
      final notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        body: body,
        orderId: orderId,
        type: type,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(notificationsCollection)
          .add(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notifications for current user
  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => AppNotification.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Stream of unread notifications for current user
  Stream<List<AppNotification>> getUnreadNotificationsStream() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to fetch unread count: $e');
    }
  }

  /// Send deadline reminder notification
  Future<void> sendDeadlineReminder({
    required String userId,
    required String clientName,
    required String style,
    required int daysRemaining,
    required String orderId,
  }) async {
    try {
      final title = 'Deadline Reminder';
      final body = daysRemaining == 0
          ? '$clientName\'s $style is due today!'
          : '$clientName\'s $style is due in $daysRemaining days';

      await createNotification(
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.deadlineReminder,
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to send deadline reminder: $e');
    }
  }

  /// Send order created notification
  Future<void> sendOrderCreatedNotification({
    required String userId,
    required String clientName,
    required String style,
    required String orderId,
  }) async {
    try {
      await createNotification(
        userId: userId,
        title: 'New Order',
        body: 'A new order for $style from $clientName has been created',
        type: NotificationType.orderCreated,
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to send order created notification: $e');
    }
  }

  /// Send order completed notification
  Future<void> sendOrderCompletedNotification({
    required String userId,
    required String clientName,
    required String style,
    required String orderId,
  }) async {
    try {
      await createNotification(
        userId: userId,
        title: 'Order Completed',
        body: '$clientName\'s $style is ready for pickup!',
        type: NotificationType.orderCompleted,
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to send order completed notification: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
