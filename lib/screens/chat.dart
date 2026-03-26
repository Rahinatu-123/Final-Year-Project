import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import 'secure_image_viewer.dart';

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
  final AudioService _audioService = AudioService();
  final ImagePicker _imagePicker = ImagePicker();

  FlutterSoundRecorder? _audioRecorder;
  Future<void>? _recorderInitFuture;
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _hasAllowedAudio = false;
  String? _recordingPath;

  // Audio playback
  late AudioPlayer _audioPlayer;
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  final Map<String, bool> _revealedSecureImages = {};

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _checkAudioPermission();
    _recorderInitFuture = _initializeAudioRecorder();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioRecorder() async {
    try {
      _audioRecorder ??= FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      await _audioRecorder!.setSubscriptionDuration(
        const Duration(milliseconds: 150),
      );
      _isRecorderReady = true;
    } catch (e) {
      _isRecorderReady = false;
      debugPrint('Error initializing recorder: $e');
      rethrow;
    }
  }

  Future<void> _ensureRecorderReady() async {
    if (_isRecorderReady) return;
    await (_recorderInitFuture ??= _initializeAudioRecorder());
    if (!_isRecorderReady) {
      throw Exception('Recorder not ready');
    }
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      setState(() {
        _isPlaying = playerState == PlayerState.playing;
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentlyPlayingUrl = null;
      });
    });
  }

  Future<void> _checkAudioPermission() async {
    final hasPermission = await _audioService.hasMicrophonePermission();
    setState(() {
      _hasAllowedAudio = hasPermission;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder?.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _hasText => _messageController.text.trim().isNotEmpty;

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
            final msgDoc = snapshot.data!.docs[index];
            final msgData = msgDoc.data() as Map<String, dynamic>;
            final senderId = (msgData['senderId'] ?? '').toString();
            final messageType = (msgData['type'] ?? '').toString();
            bool isMe = senderId == userId;

            // Safely check for style share message
            final isStyleShare =
                messageType == 'style_share' && msgData['styleData'] != null;

            // Group messages by time
            bool showTimestamp = false;
            if (index == snapshot.data!.docs.length - 1) {
              showTimestamp = true;
            }

            Widget buildMessage() {
              try {
                if (messageType == 'secure_image_request') {
                  return _buildSecureImageRequestBubble(
                    messageId: msgDoc.id,
                    messageData: msgData,
                    isMe: isMe,
                  );
                }

                if (messageType == 'secure_image') {
                  return _buildSecureImageBubble(
                    messageId: msgDoc.id,
                    messageData: msgData,
                    isMe: isMe,
                  );
                }

                if (isStyleShare) {
                  final styleData =
                      msgData['styleData'] as Map<String, dynamic>?;
                  if (styleData != null) {
                    return _buildStyleShareBubble(styleData, isMe);
                  }
                }

                // Check if message is audio
                final isAudio =
                    messageType == 'audio' && msgData['audioUrl'] != null;
                if (isAudio) {
                  return _buildAudioBubble(
                    msgData['audioUrl'].toString(),
                    (msgData['duration'] as num?)?.toInt() ?? 0,
                    isMe,
                  );
                }

                final text =
                    (msgData['text'] ?? msgData['message'] ?? 'Sent a message')
                        .toString();

                return _buildMessageBubble(text, isMe);
              } catch (e) {
                debugPrint('Message build error: $e');
                return _buildMessageBubble('Error loading message', isMe);
              }
            }

            return Column(
              children: [
                if (showTimestamp) _buildTimestamp("Today"),
                buildMessage(),
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

  Widget _buildStyleShareBubble(Map<String, dynamic> styleData, bool isMe) {
    final imageUrl = styleData['imageUrl'] ?? '';
    final styleName = styleData['name'] ?? 'Style';
    final sellerName = styleData['sellerName'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Style Image
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            // Style Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    styleName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sellerName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By $sellerName',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureImageRequestBubble({
    required String messageId,
    required Map<String, dynamic> messageData,
    required bool isMe,
  }) {
    final status = (messageData['requestStatus'] ?? 'pending').toString();
    final note = (messageData['requestNote'] ?? '').toString();
    final requestedAt = (messageData['createdAt'] as Timestamp?)?.toDate();
    final expiresAt = (messageData['expiresAt'] as Timestamp?)?.toDate();
    final canRespond = !isMe && status == 'pending';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.22),
            width: 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Secure Image Request',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.isEmpty
                  ? 'Tailor requests a private image for measurement support.'
                  : note,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  label: status.toUpperCase(),
                  color: _requestStatusColor(status),
                ),
                if (requestedAt != null)
                  _statusChip(
                    label: 'Req ${_formatShortDateTime(requestedAt)}',
                    color: AppColors.textTertiary,
                  ),
                if (expiresAt != null)
                  _statusChip(
                    label: 'Exp ${_formatShortDateTime(expiresAt)}',
                    color: AppColors.gold,
                  ),
              ],
            ),
            if (canRespond) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _denySecureImageRequest(messageId),
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      onPressed: () => _approveSecureImageRequest(
                        messageId: messageId,
                        messageData: messageData,
                      ),
                      label: const Text('Approve & Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _requestStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'denied':
        return AppColors.error;
      case 'expired':
        return AppColors.gold;
      case 'deleted':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildSecureImageBubble({
    required String messageId,
    required Map<String, dynamic> messageData,
    required bool isMe,
  }) {
    final imageUrl = (messageData['secureImageUrl'] ?? '').toString();
    final watermarkText = (messageData['watermarkText'] ?? '').toString();
    final deleted = messageData['secureDeleted'] == true;
    final expiresAt = (messageData['expiresAt'] as Timestamp?)?.toDate();
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final canShowImage = imageUrl.isNotEmpty && !deleted && !isExpired;
    final isRevealed = _revealedSecureImages[messageId] ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.warmGradient : null,
          color: isMe ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isMe
              ? AppShadows.colored(AppColors.coral)
              : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Measurement Image',
              style: AppTextStyles.labelSmall.copyWith(
                color: isMe ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (!canShowImage)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.18)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    deleted
                        ? 'Image deleted'
                        : isExpired
                        ? 'Image expired'
                        : 'Image unavailable',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecureImageViewer(
                        imageUrl: imageUrl,
                        watermarkText: watermarkText,
                        isExpired: isExpired,
                      ),
                    ),
                  );
                },
                onLongPressStart: (_) {
                  setState(() {
                    _revealedSecureImages[messageId] = true;
                  });
                },
                onLongPressEnd: (_) {
                  setState(() {
                    _revealedSecureImages[messageId] = false;
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: isRevealed ? 0 : 7,
                          sigmaY: isRevealed ? 0 : 7,
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (!isRevealed)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.22),
                            alignment: Alignment.center,
                            child: Text(
                              'Hold to reveal',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: SecureWatermarkOverlay(text: watermarkText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              canShowImage
                  ? 'No download. Tap to open secure viewer.'
                  : 'Access removed based on privacy controls.',
              style: AppTextStyles.labelSmall.copyWith(
                color: isMe ? Colors.white70 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.month}/${value.day} ${two(value.hour)}:${two(value.minute)}';
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
            // Share/Upload button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: _showSecureImageActions,
                tooltip: 'Share/Upload',
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

            // Always show mic button with send arrow when text is present
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _hasText
                  ? _sendMessage
                  : () async {
                      final hasPermission = await _audioService
                          .requestMicrophonePermission();
                      if (hasPermission) {
                        setState(() => _hasAllowedAudio = true);
                        _showAudioRecordingUI();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Microphone permission required for audio recording',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _hasText ? AppColors.warmGradient : null,
                  color: _hasText ? null : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? AppShadows.colored(AppColors.coral)
                      : null,
                ),
                child: Icon(
                  _hasText ? Icons.send : Icons.mic,
                  color: _hasText ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSecureImageActions() async {
    if (userId == null) return;

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final chatData = chatDoc.data() ?? <String, dynamic>{};
    final tailorId = (chatData['tailorId'] ?? '').toString();
    final isTailor = tailorId.isNotEmpty && tailorId == userId;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_person_outlined),
                title: const Text('Request Secure Client Image'),
                subtitle: Text(
                  isTailor
                      ? 'Client approval is required before upload.'
                      : 'Use this only when acting as tailor in this order.',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _promptSecureImageRequest();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptSecureImageRequest() async {
    final noteController = TextEditingController(
      text: 'Please share a full-body image for accurate measurements.',
    );
    final orderIdController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Secure Image Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Request Note',
                    hintText: 'Explain why the image is needed.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Order ID (required for lifecycle auto-delete)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    final shouldSend = result == true;
    if (!shouldSend || userId == null) {
      noteController.dispose();
      orderIdController.dispose();
      return;
    }

    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    final requestRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();

    await requestRef.set({
      'type': 'secure_image_request',
      'requestId': requestRef.id,
      'senderId': userId,
      'text': 'Requested a secure image for measurements',
      'requestNote': noteController.text.trim(),
      'requestStatus': 'pending',
      'orderId': orderIdController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'lastMessage': 'Secure image request sent',
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([userId]),
      },
      SetOptions(merge: true),
    );

    noteController.dispose();
    orderIdController.dispose();
  }

  Future<void> _denySecureImageRequest(String messageId) async {
    if (userId == null) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'requestStatus': 'denied',
          'respondedBy': userId,
          'respondedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _approveSecureImageRequest({
    required String messageId,
    required Map<String, dynamic> messageData,
  }) async {
    if (userId == null) return;

    final expiresAt = (messageData['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'requestStatus': 'expired',
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request already expired.')),
        );
      }
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
    );
    if (picked == null) return;

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final chatData = chatDoc.data() ?? <String, dynamic>{};
    final participants = List<String>.from(
      (chatData['participants'] as List<dynamic>? ?? const []),
    );
    if (!participants.contains(userId)) {
      participants.add(userId!);
    }

    final shareRef = FirebaseFirestore.instance
        .collection('secure_image_shares')
        .doc();

    final watermarkText =
        'UID:${_maskUid(userId!)} | ${DateTime.now().toIso8601String()}';
    final safeExpiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));

    await shareRef.set({
      'chatId': widget.chatId,
      'requestId': messageId,
      'orderId': (messageData['orderId'] ?? '').toString(),
      'participants': participants,
      'uploaderId': userId,
      'status': 'active',
      'watermarkText': watermarkText,
      'expiresAt': Timestamp.fromDate(safeExpiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final file = File(picked.path);
    final secureImageUrl = await _uploadToCloudinary(
      file,
      shareRef.id,
      widget.chatId,
    );

    await shareRef.update({
      'secureImageUrl': secureImageUrl,
      'cloudinaryPublicId': _extractCloudinaryPublicId(secureImageUrl),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'type': 'secure_image',
          'senderId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'text': 'Shared a secure image',
          'secureShareId': shareRef.id,
          'secureImageUrl': secureImageUrl,
          'watermarkText': watermarkText,
          'expiresAt': Timestamp.fromDate(safeExpiresAt),
          'orderId': (messageData['orderId'] ?? '').toString(),
          'requestId': messageId,
          'secureDeleted': false,
        });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'requestStatus': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': userId,
          'secureShareId': shareRef.id,
        });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'lastMessage': 'Secure image shared',
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([userId]),
      },
      SetOptions(merge: true),
    );

    if (await file.exists()) {
      await file.delete();
    }
  }

  String _maskUid(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 4)}***${uid.substring(uid.length - 4)}';
  }

  Future<String> _uploadToCloudinary(
    File imageFile,
    String shareId,
    String chatId,
  ) async {
    const cloudName = 'dr8f7af8z';
    const uploadPreset = 'fashionHub_app';
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['public_id'] = 'fashionhub/userSharedImages/$shareId'
        ..fields['resource_type'] = 'image'
        ..fields['context'] = 'secureShareId=$shareId|chatId=$chatId'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));

      var response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Cloudinary upload timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }

      final responseData = jsonDecode(await response.stream.bytesToString());
      final uploadedUrl = responseData['secure_url'] ?? responseData['url'];
      if (uploadedUrl == null) {
        throw Exception('No URL in Cloudinary response');
      }
      return uploadedUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      rethrow;
    }
  }

  String _extractCloudinaryPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final versionIndex =
            pathSegments.indexWhere((s) => s.startsWith('v'));
        if (versionIndex >= 0 && versionIndex + 1 < pathSegments.length) {
          final publicIdWithExtension =
              pathSegments.sublist(versionIndex + 1).join('/');
          return publicIdWithExtension.replaceAll(RegExp(r'\.[^.]*$'), '');
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Build audio message bubble with play button
  Widget _buildAudioBubble(String audioUrl, int duration, bool isMe) {
    String durationText = _formatDuration(duration);
    bool isPlayingThisAudio = _currentlyPlayingUrl == audioUrl && _isPlaying;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                await _playAudio(audioUrl);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlayingThisAudio ? Icons.pause : Icons.play_arrow,
                  color: isMe ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe ? Colors.white70 : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Play audio from URL
  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_currentlyPlayingUrl == audioUrl && _isPlaying) {
        // Pause if this audio is already playing
        await _audioPlayer.pause();
      } else if (_currentlyPlayingUrl == audioUrl) {
        // Resume if paused
        await _audioPlayer.resume();
      } else {
        // Stop current audio and play new one
        if (_isPlaying) {
          await _audioPlayer.stop();
        }
        setState(() {
          _currentlyPlayingUrl = audioUrl;
        });
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  /// Format duration in seconds to MM:SS format
  String _formatDuration(int seconds) {
    if (seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Show WhatsApp-style audio recording UI
  void _showAudioRecordingUI() {
    bool isRecording = false;
    int recordingSeconds = 0;
    Timer? recordingTimer;
    bool hasInitialized = false;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> startRecording() async {
              if (hasInitialized) return;
              hasInitialized = true;

              try {
                final hasPermission = await _audioService
                    .requestMicrophonePermission();
                if (!hasPermission) {
                  throw Exception('Microphone permission denied');
                }

                await _ensureRecorderReady();

                final recordingPath = await _audioService
                    .generateAudioFilePath();

                _recordingPath = recordingPath;

                await _audioRecorder!.startRecorder(
                  toFile: recordingPath,
                  codec: Codec.aacADTS,
                );

                setModalState(() {
                  isRecording = true;
                });
                _isRecording = true;

                // Start timer
                recordingTimer = Timer.periodic(const Duration(seconds: 1), (
                  timer,
                ) {
                  setModalState(() {
                    recordingSeconds++;
                  });
                });
              } catch (e) {
                debugPrint('Auto-start error: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recording error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }

            // Auto-start recording when modal opens
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startRecording();
            });

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mic icon with animation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isRecording
                          ? Colors.red.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 48,
                      color: isRecording ? Colors.red : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recording time
                  Text(
                    isRecording
                        ? '${recordingSeconds ~/ 60}:${(recordingSeconds % 60).toString().padLeft(2, '0')}'
                        : 'Starting...',
                    style: AppTextStyles.h3.copyWith(
                      color: isRecording ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRecording
                        ? 'Tap send when done'
                        : 'Initializing recorder...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      GestureDetector(
                        onTap: () async {
                          recordingTimer?.cancel();
                          if (isRecording &&
                              (_audioRecorder?.isRecording ?? false)) {
                            await _audioRecorder!.stopRecorder();
                          }
                          _isRecording = false;
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                      ),

                      // Record/Send button
                      GestureDetector(
                        onTap: () async {
                          if (!isRecording) {
                            // Try to manually start recording
                            try {
                              final hasPermission = await _audioService
                                  .requestMicrophonePermission();
                              if (!hasPermission) {
                                throw Exception('Microphone permission denied');
                              }

                              await _ensureRecorderReady();

                              final recordingPath = await _audioService
                                  .generateAudioFilePath();
                              _recordingPath = recordingPath;

                              await _audioRecorder!.startRecorder(
                                toFile: recordingPath,
                                codec: Codec.aacADTS,
                              );

                              setModalState(() {
                                isRecording = true;
                              });
                              _isRecording = true;

                              recordingTimer = Timer.periodic(
                                const Duration(seconds: 1),
                                (timer) {
                                  setModalState(() {
                                    recordingSeconds++;
                                  });
                                },
                              );
                            } catch (e) {
                              debugPrint('Manual start error: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          } else {
                            // Stop and send recording
                            recordingTimer?.cancel();
                            try {
                              final path = await _audioRecorder!.stopRecorder();
                              _isRecording = false;

                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              if (path != null && path.isNotEmpty) {
                                await _uploadAndSendAudio(
                                  path,
                                  recordingSeconds,
                                );
                              }
                            } catch (e) {
                              debugPrint('Error stopping recording: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error sending: $e')),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isRecording
                                ? AppColors.warmGradient
                                : null,
                            color: !isRecording
                                ? AppColors.surfaceVariant
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: isRecording
                                ? AppShadows.colored(AppColors.coral)
                                : null,
                          ),
                          child: Icon(
                            isRecording ? Icons.send : Icons.mic,
                            color: isRecording
                                ? Colors.white
                                : AppColors.textTertiary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Upload audio file and send message
  Future<void> _uploadAndSendAudio(String filePath, int durationSeconds) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading audio...')));
      }

      // Upload to Firebase Storage
      final downloadUrl = await _audioService.uploadAudio(
        File(filePath),
        widget.chatId,
        userId ?? 'unknown',
      );

      if (downloadUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload audio')),
          );
        }
        return;
      }

      // Send audio message
      await _sendAudioMessage(downloadUrl, durationSeconds);

      // Delete local file
      await _audioService.deleteLocalAudio(filePath);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio message sent!')));
      }
    } catch (e) {
      print('Error uploading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Send audio message to Firebase
  Future<void> _sendAudioMessage(String audioUrl, int durationSeconds) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'type': 'audio',
            'audioUrl': audioUrl,
            'duration': durationSeconds,
            'senderId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({
            'lastMessage': 'Sent a voice message',
            'updatedAt': FieldValue.serverTimestamp(),
            'participants': FieldValue.arrayUnion([userId]),
          }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending audio: $e')));
      }
    }
  }
}
