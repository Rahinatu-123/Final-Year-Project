import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([userId]),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(
                Icons.person,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Online",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: const Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
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

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyChat();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var msg = snapshot.data!.docs[index];
            bool isMe = msg['senderId'] == userId;

            // Group messages by time
            bool showTimestamp = false;
            if (index == snapshot.data!.docs.length - 1) {
              showTimestamp = true;
            }

            return Column(
              children: [
                if (showTimestamp) _buildTimestamp("Today"),
                _buildMessageBubble(msg['text'], isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Start the conversation",
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "Send a message to begin discussing\nyour fashion needs",
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(String time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Text(time, style: AppTextStyles.labelSmall),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.warmGradient : null,
          color: isMe ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe
              ? AppShadows.colored(AppColors.coral)
              : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "12:30 PM",
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe ? Colors.white70 : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppColors.textTertiary,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.colored(AppColors.coral),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
