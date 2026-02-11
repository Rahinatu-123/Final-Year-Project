import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a chat message
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String? imageUrl;
  final String? orderId; // Reference to an order if created from chat
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.imageUrl,
    this.orderId,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'orderId': orderId,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      orderId: map['orderId'],
      isRead: map['isRead'] ?? false,
    );
  }
}

/// Model for a conversation
class Conversation {
  final String id;
  final String tailorId;
  final String clientId;
  final String tailorName;
  final String clientName;
  final String? tailorImageUrl;
  final String? clientImageUrl;
  final DateTime lastMessageTime;
  final String lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.tailorId,
    required this.clientId,
    required this.tailorName,
    required this.clientName,
    this.tailorImageUrl,
    this.clientImageUrl,
    required this.lastMessageTime,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'clientId': clientId,
      'tailorName': tailorName,
      'clientName': clientName,
      'tailorImageUrl': tailorImageUrl,
      'clientImageUrl': clientImageUrl,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, String docId) {
    return Conversation(
      id: docId,
      tailorId: map['tailorId'] ?? '',
      clientId: map['clientId'] ?? '',
      tailorName: map['tailorName'] ?? '',
      clientName: map['clientName'] ?? '',
      tailorImageUrl: map['tailorImageUrl'],
      clientImageUrl: map['clientImageUrl'],
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}

/// Service for managing chat operations
class ChatService {
  static final ChatService _instance = ChatService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String conversationsCollection = 'conversations';
  static const String messagesSubcollection = 'messages';

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  /// Create or get a conversation between tailor and client
  Future<String> getOrCreateConversation({
    required String tailorId,
    required String clientId,
    required String tailorName,
    required String clientName,
    String? tailorImageUrl,
    String? clientImageUrl,
  }) async {
    try {
      // Check if conversation already exists
      String conversationId = _generateConversationId(tailorId, clientId);
      DocumentSnapshot doc = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return conversationId;
      }

      // Create new conversation
      Conversation newConversation = Conversation(
        id: conversationId,
        tailorId: tailorId,
        clientId: clientId,
        tailorName: tailorName,
        clientName: clientName,
        tailorImageUrl: tailorImageUrl,
        clientImageUrl: clientImageUrl,
        lastMessageTime: DateTime.now(),
        lastMessage: 'Conversation started',
      );

      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .set(newConversation.toMap());

      return conversationId;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    String? imageUrl,
    String? orderId,
  }) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get conversation details
      DocumentSnapshot convDoc = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .get();
      Conversation conversation = Conversation.fromMap(
        convDoc.data() as Map<String, dynamic>,
        convDoc.id,
      );

      // Determine sender info
      String senderName = currentUserId == conversation.tailorId
          ? conversation.tailorName
          : conversation.clientName;

      ChatMessage newMessage = ChatMessage(
        id: '', // Will be set by Firestore
        conversationId: conversationId,
        senderId: currentUserId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        orderId: orderId,
      );

      // Add message to subcollection
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection(messagesSubcollection)
          .add(newMessage.toMap());

      // Update conversation's last message
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({
            'lastMessageTime': Timestamp.fromDate(newMessage.timestamp),
            'lastMessage': message,
          });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all messages in a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection(messagesSubcollection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Stream of messages for real-time updates
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(conversationsCollection)
        .doc(conversationId)
        .collection(messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ChatMessage.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  /// Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      QuerySnapshot snapshot = await _firestore
          .collection(conversationsCollection)
          .where('tailorId', isEqualTo: currentUserId)
          .get();

      final conversations = snapshot.docs
          .map(
            (doc) => Conversation.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Also get conversations where user is a client
      QuerySnapshot clientSnapshot = await _firestore
          .collection(conversationsCollection)
          .where('clientId', isEqualTo: currentUserId)
          .get();

      final clientConversations = clientSnapshot.docs
          .map(
            (doc) => Conversation.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      conversations.addAll(clientConversations);
      return conversations;
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  /// Stream of conversations for real-time updates
  Stream<List<Conversation>> getConversationsStream() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(conversationsCollection)
        .where('tailorId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Conversation.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  /// Generate unique conversation ID
  String _generateConversationId(String tailorId, String clientId) {
    final ids = [tailorId, clientId]..sort();
    return ids.join('_');
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .collection(messagesSubcollection)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Reset unread count
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({'unreadCount': 0});
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
