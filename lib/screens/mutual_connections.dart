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

  Future<Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchUsersByIds(List<String> userIds) async {
    final result = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    if (userIds.isEmpty) return result;

    const chunkSize = 10;
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end = (i + chunkSize > userIds.length)
          ? userIds.length
          : i + chunkSize;
      final chunk = userIds.sublist(i, end);

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final userDoc in userSnapshot.docs) {
        result[userDoc.id] = userDoc;
      }
    }

    return result;
  }

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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  final chats = snapshot.data?.docs ?? [];
                  if (chats.isEmpty) {
                    return _buildEmptyState();
                  }

                  final chatByOtherUser = <String, Map<String, dynamic>>{};
                  final otherUserIds = <String>{};

                  for (final chatDoc in chats) {
                    final chatData = chatDoc.data();
                    final participants =
                        (chatData['participants'] as List<dynamic>? ?? [])
                            .map((e) => e.toString())
                            .toList();

                    String? otherUserId;
                    for (final participant in participants) {
                      if (participant != currentUser?.uid) {
                        otherUserId = participant;
                        break;
                      }
                    }

                    if (otherUserId == null || otherUserId.isEmpty) {
                      continue;
                    }

                    otherUserIds.add(otherUserId);

                    final existing = chatByOtherUser[otherUserId];
                    final existingMs =
                        (existing?['updatedAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    final currentMs =
                        (chatData['updatedAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;

                    if (existing == null || currentMs > existingMs) {
                      chatByOtherUser[otherUserId] = chatData;
                    }
                  }

                  if (otherUserIds.isEmpty) {
                    return _buildEmptyState();
                  }

                  return FutureBuilder<
                    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
                  >(
                    future: _fetchUsersByIds(otherUserIds.toList()),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        );
                      }

                      final usersById = userSnapshot.data ??
                          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

                      final sortedUserIds = otherUserIds.toList()
                        ..sort((a, b) {
                          final aData =
                              chatByOtherUser[a] ?? const <String, dynamic>{};
                          final bData =
                              chatByOtherUser[b] ?? const <String, dynamic>{};

                          final aMs =
                              (aData['updatedAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;
                          final bMs =
                              (bData['updatedAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0;

                          return bMs.compareTo(aMs);
                        });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: sortedUserIds.length,
                        itemBuilder: (context, index) {
                          final userId = sortedUserIds[index];
                          final userDoc = usersById[userId];
                          final userData = userDoc?.data() ??
                              <String, dynamic>{'username': 'Unknown User'};
                          final chatData =
                              chatByOtherUser[userId] ??
                              const <String, dynamic>{};

                          final lastMessage =
                              (chatData['lastMessage'] ?? 'Tap to start chatting')
                                  .toString();
                          final lastMessageTime =
                              _formatTimestamp(chatData['updatedAt'] as Timestamp?);
                          final unreadRaw =
                              (chatData['unreadCount'] as Map<String, dynamic>?) ??
                              const <String, dynamic>{};
                          final unreadCount = (unreadRaw[currentUser?.uid] ?? 0)
                              as int;

                          return _buildChatTile(
                            context,
                            userId,
                            userData,
                            lastMessage: lastMessage,
                            lastMessageTime: lastMessageTime,
                            unreadCount: unreadCount,
                          );
                        },
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
    {
    required String lastMessage,
    required String lastMessageTime,
    required int unreadCount,
  }
  ) {
    final username = userData['username'] ?? "Unknown User";
    final profilePictureUrl = userData['profilePictureUrl'];

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
                        profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                    backgroundColor: AppColors.surfaceVariant,
                    child:
                        profilePictureUrl == null || profilePictureUrl.isEmpty
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
                      Expanded(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                "No Conversations Yet",
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Start a conversation from a profile or your clients list. Your chats will appear here automatically.",
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
}
