import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import 'try_on.dart';

class StyleDetailPage extends StatefulWidget {
  final Map<String, dynamic> style;
  final String? category;
  final String? styleId;
  final String? personImagePath;

  const StyleDetailPage({
    super.key,
    required this.style,
    this.category,
    this.styleId,
    this.personImagePath,
  });

  @override
  State<StyleDetailPage> createState() => _StyleDetailPageState();
}

class _StyleDetailPageState extends State<StyleDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Save to Device',
                onPressed: () => _saveStyleToDevice(widget.style),
              ),
            ],
          ),
          // Main Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Image.network(
                    widget.style['imageUrl'] ?? '',
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 400,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.style['name'] ?? 'Style',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 8),
                      // Category
                      if (widget.style['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.style['category'],
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Description
                      Text('Description', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(
                        widget.style['description'] ??
                            'No description available',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Seller Info
                      if (widget.style['sellerId'] != null) ...[
                        Text('Creator', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.warmGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.style['sellerName'] ??
                                          'Fashion Creator',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Style Designer',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final styleImageUrl =
                                      widget.style['imageUrl'] as String?;

                                  if (styleImageUrl == null ||
                                      styleImageUrl.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Style image URL not found',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (!mounted) return;

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TryOnScreen(
                                        personImagePath: widget.personImagePath,
                                        garmentImagePath: styleImageUrl,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Try On'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _shareStyle(widget.style),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Related Styles Section
                      Text('More from this category', style: AppTextStyles.h4),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Related Styles List
          if (widget.style['category'] != null)
            SliverToBoxAdapter(
              child: SizedBox(height: 280, child: _buildRelatedStyles()),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildRelatedStyles() {
    final category = widget.style['category'] ?? widget.category;
    final currentStyleId = widget.styleId;

    debugPrint('DEBUG: Attempting to find related styles');
    debugPrint('DEBUG: Category value: "$category"');
    debugPrint('DEBUG: Current Style ID: "$currentStyleId"');
    debugPrint('DEBUG: Current style name: ${widget.style['name']}');

    if (category == null || category.toString().trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                'DEBUG: No category\nValue: "$category"',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('styles')
          .where('category', isEqualTo: category.toString().trim())
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint('DEBUG: StreamBuilder state - ${snapshot.connectionState}');
        if (!snapshot.hasData) {
          debugPrint('DEBUG: No data in snapshot');
          return const Center(child: CircularProgressIndicator());
        }

        debugPrint('DEBUG: Snapshot has ${snapshot.data!.docs.length} documents');

        // Filter out the current style using document ID (more reliable)
        final styles = snapshot.data!.docs.where((doc) {
          final docId = doc.id;
          final isCurrentStyle =
              currentStyleId != null && docId == currentStyleId;
          debugPrint('DEBUG: Doc ID: $docId, is current: $isCurrentStyle');
          return !isCurrentStyle;
        }).toList();

        debugPrint('DEBUG: After filtering by ID: ${styles.length} styles found');

        if (styles.isEmpty) {
          // If filtering by ID found nothing, try filtering by name as fallback
          debugPrint('DEBUG: No styles after ID filter, trying name filter...');
          final stylesByName = snapshot.data!.docs.where((doc) {
            final docData = doc.data() as Map<String, dynamic>;
            return docData['name'] != widget.style['name'];
          }).toList();

          debugPrint(
            'DEBUG: After name filter: ${stylesByName.length} styles found',
          );

          if (stylesByName.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DEBUG:\nCategory: "$category"\nTotal found: ${snapshot.data!.docs.length}\nAfter filter: 0\nCurrent ID: "$currentStyleId"',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No other styles in this category',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildRelatedStylesList(stylesByName, category);
        }

        return _buildRelatedStylesList(styles, category);
      },
    );
  }

  Widget _buildRelatedStylesList(
    List<QueryDocumentSnapshot> styles,
    String category,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final relatedStyle = styles[index].data() as Map<String, dynamic>;
        final styleId = styles[index].id;

        return Padding(
          padding: EdgeInsets.only(right: index == styles.length - 1 ? 0 : 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StyleDetailPage(
                    style: relatedStyle,
                    category: category,
                    styleId: styleId,
                  ),
                ),
              );
            },
            child: _buildRelatedStyleCard(relatedStyle),
          ),
        );
      },
    );
  }

  Widget _buildRelatedStyleCard(Map<String, dynamic> style) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              style['imageUrl'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.style, size: 48),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (style['sellerName'] != null)
                      Text(
                        style['sellerName'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareStyle(Map<String, dynamic> style) {
    _showShareDialog(style);
  }

  void _showShareDialog(Map<String, dynamic> style) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Share Style', style: AppTextStyles.h4),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Share with Connections
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Text(
                        'Share with Connections',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _buildConnectionsList(currentUser.uid, style),
                    const SizedBox(height: 24),
                    // Section: Other Share Options (no label)
                    _buildOtherShareOptions(style),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsList(String userId, Map<String, dynamic> style) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('connections')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final connections = snapshot.data!.docs;

        if (connections.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No connections yet. Follow people to share with them!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final connection =
                  connections[index].data() as Map<String, dynamic>;
              final connectionUserId = connections[index].id;
              final connectionName = connection['userName'] ?? 'User';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(connectionUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final profileImage = userData['profileImage'] ?? '';
                  final fullName = userData['fullName'] ?? connectionName;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _sendViaChat(connectionUserId, fullName, style),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: profileImage.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      profileImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.person),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 30),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 70,
                          child: Text(
                            fullName,
                            style: AppTextStyles.labelSmall,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOtherShareOptions(Map<String, dynamic> style) {
    final shareOptions = [
      {
        'icon': Icons.share_outlined,
        'label': 'WhatsApp',
        'color': const Color(0xFF25D366),
      },
      {
        'icon': Icons.photo_camera_outlined,
        'label': 'Instagram Story',
        'color': const Color(0xFFE4405F),
      },
      {
        'icon': Icons.mail_outline,
        'label': 'Email',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.ios_share,
        'label': 'More',
        'color': AppColors.textSecondary,
      },
    ];

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 16,
      runSpacing: 12,
      children: shareOptions
          .map(
            (option) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (option['label'] == 'More') {
                  _shareStyleDefault(style);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (option['color'] as Color).withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: option['color'] as Color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 60,
                    child: Text(
                      option['label'] as String,
                      style: AppTextStyles.labelSmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _sendViaChat(
    String userId,
    String userName,
    Map<String, dynamic> style,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Create chat ID (combination of both user IDs, sorted for consistency)
    final ids = [currentUser.uid, userId];
    ids.sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final styleName = style['name'] ?? 'Check out this style';
    final imageUrl = style['imageUrl'] ?? '';
    final description = style['description'] ?? '';
    final sellerName = style['sellerName'] ?? '';

    // Send as a structured message with style data
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': styleName,
          'senderId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'style_share',
          'styleData': {
            'name': styleName,
            'description': description,
            'sellerName': sellerName,
            'imageUrl': imageUrl,
          },
        });

    FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': styleName,
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([currentUser.uid, userId]),
    }, SetOptions(merge: true));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent to $userName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareStyleDefault(Map<String, dynamic> style) {
    final name = style['name'] ?? 'Check out this style';
    final imageUrl = style['imageUrl'] ?? '';
    final description = style['description'] ?? '';
    final sellerName = style['sellerName'] ?? '';

    final shareText = '$name\nBy $sellerName\n\n$description\n\n$imageUrl';

    SharePlus.instance.share(
      ShareParams(text: shareText.isNotEmpty ? shareText : 'Check out this style on FashionHub'),
    );
  }

  Future<void> _saveStyleToDevice(Map<String, dynamic> style) async {
    try {
      final imageUrl = style['imageUrl'] as String?;
      final styleName = style['name'] as String? ?? 'style';

      if (imageUrl == null || imageUrl.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image to save'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving style to device...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Get documents directory
        final documentsDir = await getApplicationDocumentsDirectory();
        final fashionHubDir = Directory(
          '${documentsDir.path}/FashionHub/Styles',
        );

        // Create directory if it doesn't exist
        if (!await fashionHubDir.exists()) {
          await fashionHubDir.create(recursive: true);
        }

        // Create filename with timestamp
        final filename =
            '${styleName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${fashionHubDir.path}/$filename';

        // Save image to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Style saved to Downloads'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving style: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
