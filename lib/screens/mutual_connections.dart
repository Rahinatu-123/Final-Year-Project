import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fashionhub/screens/find_connection.dart';
import 'package:fashionhub/screens/chat.dart';
import '../theme/app_theme.dart';

// =====================================================
// CHAT PAGE (WHATSAPP STYLE)
// =====================================================

class MutualConnectionsPage extends StatefulWidget {
  const MutualConnectionsPage({super.key});

  @override
  State<MutualConnectionsPage> createState() => _MutualConnectionsPageState();
}

class _MutualConnectionsPageState extends State<MutualConnectionsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindConnectionPage(),
                ),
              );
            },
            tooltip: "Search All Users",
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            // Chat list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getMutualConnections(),
                builder: (context, snapshot) {
                  // Debug: Print current user ID
                  print('Current user ID: ${currentUser?.uid}');

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  final mutualUsers = snapshot.data!.docs.where((doc) {
                    return doc.id != currentUser?.uid; // Don't show yourself
                  }).toList();

                  print(
                    'Number of mutual connections found: ${mutualUsers.length}',
                  );

                  if (mutualUsers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: mutualUsers.length,
                    itemBuilder: (context, index) {
                      var userDoc = mutualUsers[index];
                      var userData = userDoc.data() as Map<String, dynamic>;

                      // Debug: Print user data
                      print('User ${index + 1}: ${userDoc.id} - ${userData}');

                      return _buildChatTile(
                        context,
                        userDoc.id,
                        userData,
                        false, // Will calculate unread count
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Messages", style: AppTextStyles.h2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
    bool hasUnread,
  ) {
    final username = userData['username'] ?? "Unknown User";
    final profilePictureUrl = userData['profilePictureUrl'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser?.uid)
          .snapshots(),
      builder: (context, chatSnapshot) {
        String lastMessage = "Tap to start chatting";
        String lastMessageTime = "Now";
        int unreadCount = 0;

        if (chatSnapshot.hasData) {
          for (final chatDoc in chatSnapshot.data!.docs) {
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final participants =
                chatData['participants'] as List<dynamic>? ?? [];

            if (participants.contains(userId)) {
              lastMessage = chatData['lastMessage'] ?? "Tap to start chatting";
              lastMessageTime = _formatTimestamp(chatData['updatedAt']);
              unreadCount = chatData['unreadCount']?[currentUser?.uid] ?? 0;
              break;
            }
          }
        }

        return GestureDetector(
          onTap: () {
            // Create or open chat with this user
            _createOrOpenChat(userId, username);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              boxShadow: AppShadows.soft,
              border: unreadCount > 0
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: AppColors.warmGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            profilePictureUrl != null &&
                                profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl!)
                            : null,
                        backgroundColor: AppColors.surfaceVariant,
                        child:
                            profilePictureUrl == null ||
                                profilePictureUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppColors.textTertiary,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            username,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            lastMessageTime,
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.warmGradient,
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.xl,
                                ),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Now";

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return "Now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${messageTime.day}/${messageTime.month}/${messageTime.year}";
  }

  Future<void> _createOrOpenChat(
    String otherUserId,
    String otherUserName,
  ) async {
    if (currentUser == null) return;

    // Check if chat already exists
    final existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser!.uid)
        .get();

    String? chatId;
    for (final doc in existingChat.docs) {
      final participants = doc['participants'] as List<dynamic>? ?? [];
      if (participants.contains(otherUserId)) {
        chatId = doc.id;
        break;
      }
    }

    // Create new chat if doesn't exist
    if (chatId == null) {
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUser!.uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Tap to start chatting',
        'unreadCount': {currentUser!.uid: 0, otherUserId: 0},
      });
      chatId = newChat.id;
    }

    // Navigate to chat
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(chatId: chatId!, otherUserName: otherUserName),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "No Mutual Connections Yet",
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Start conversations by connecting with other tailors, seamstresses, and fabric sellers in your community.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Find People",
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Tap the search icon to find and follow other professionals",
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Follow & Get Followed",
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "When they follow you back, you can chat",
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ================= GET MUTUAL CONNECTIONS =================

  Stream<QuerySnapshot> _getMutualConnections() {
    if (currentUser == null) return const Stream.empty();

    // Get users that current user is following, then filter for mutual connections
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('following')
        .snapshots()
        .asyncExpand((followingSnapshot) async* {
          // Get list of user IDs that current user is following
          final followingIds = followingSnapshot.docs
              .map((doc) => doc.id)
              .toList();

          if (followingIds.isEmpty) {
            // Return empty result using a condition that won't match
            final emptySnap = await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, isEqualTo: '__nonexistent__')
                .get();
            yield emptySnap;
            return;
          }

          // Filter for mutual connections (those who follow back)
          final mutualUsers = <String>[];

          for (final userId in followingIds) {
            try {
              final followBackDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('following')
                  .doc(currentUser!.uid)
                  .get();

              if (followBackDoc.exists) {
                mutualUsers.add(userId);
              }
            } catch (e) {
              print('Error checking follow back for $userId: $e');
              continue;
            }
          }

          // Return the mutual users' full documents
          if (mutualUsers.isEmpty) {
            final emptySnap = await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, isEqualTo: '__nonexistent__')
                .get();
            yield emptySnap;
            return;
          }

          final result = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: mutualUsers)
              .get();
          yield result;
        });
  }
}
