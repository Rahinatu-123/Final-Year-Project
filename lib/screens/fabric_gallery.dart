import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'chat.dart';

class FabricGalleryPage extends StatefulWidget {
  const FabricGalleryPage({
    super.key,
    required this.title,
    required this.categories,
  });

  final String? title;
  final List<String> categories;

  @override
  State<FabricGalleryPage> createState() => _FabricGalleryPageState();
}

class _FabricGalleryPageState extends State<FabricGalleryPage> {
  String _selectedCategory = 'All';
  late List<String> fabricCategories;

  @override
  void initState() {
    super.initState();
    fabricCategories = widget.categories.isNotEmpty
        ? ['All', ...widget.categories]
        : [
            'All',
            'kenta',
            'ankara',
            'batik',
            'organza',
            'velvet',
            'chiffon',
            'lace',
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.title ?? "Fabric Gallery",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(child: _buildFabricGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: fabricCategories.length,
        itemBuilder: (context, index) {
          final category = fabricCategories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(30),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFabricGrid() {
    Query query = FirebaseFirestore.instance.collection('fabrics');

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.texture, size: 64),
                const SizedBox(height: 16),
                Text("No fabrics found"),
              ],
            ),
          );
        }

        final fabrics = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: fabrics.length,
          itemBuilder: (context, index) {
            var fabric = fabrics[index].data() as Map<String, dynamic>;
            return _buildFabricCard(fabric, fabrics[index].id);
          },
        );
      },
    );
  }

  Widget _buildFabricCard(Map<String, dynamic> fabric, String fabricId) {
    return GestureDetector(
      onTap: () => _showFabricDetail(fabric),
      child: Container(
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
                fabric['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.texture, size: 48),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                        fabric['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (fabric['description'] != null)
                        Text(
                          fabric['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        fabric['price'] != null ? 'GHS ${fabric['price']}' : '',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFabricDetail(Map<String, dynamic> fabric) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      child: Image.network(
                        fabric['imageUrl'] ?? '',
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 250,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.texture, size: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(fabric['name'] ?? '', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    if (fabric['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          fabric['category'],
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (fabric['description'] != null)
                      Text(
                        fabric['description'],
                        style: AppTextStyles.bodyMedium,
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          fabric['price'] != null
                              ? 'GHS ${fabric['price']}'
                              : '',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {
                            _shareFabric(fabric);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Implement order functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Order functionality coming soon!',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Order',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
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

  void _shareFabric(Map<String, dynamic> fabric) {
    _showFabricShareDialog(fabric);
  }

  void _showFabricShareDialog(Map<String, dynamic> fabric) {
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
                  Text('Share Fabric', style: AppTextStyles.h4),
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
                    _buildFabricConnectionsList(currentUser.uid, fabric),
                    const SizedBox(height: 24),
                    // Section: Other Share Options (no label)
                    _buildFabricOtherShareOptions(fabric),
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

  Widget _buildFabricConnectionsList(
    String userId,
    Map<String, dynamic> fabric,
  ) {
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
                          onTap: () => _sendFabricViaChat(
                            connectionUserId,
                            fullName,
                            fabric,
                          ),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.1),
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
                                      errorBuilder: (_, __, ___) =>
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

  Widget _buildFabricOtherShareOptions(Map<String, dynamic> fabric) {
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
                  _shareFabricDefault(fabric);
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
                      color: (option['color'] as Color).withOpacity(0.15),
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

  void _sendFabricViaChat(
    String userId,
    String userName,
    Map<String, dynamic> fabric,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Create chat ID (combination of both user IDs, sorted for consistency)
    final ids = [currentUser.uid, userId];
    ids.sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final fabricName = fabric['name'] ?? 'Check out this fabric';
    final imageUrl = fabric['imageUrl'] ?? '';
    final price = fabric['price'] ?? '';

    final shareMessage =
        'Check out this fabric: $fabricName\nPrice: GHS $price\n$imageUrl';

    // Send the message via chat
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': shareMessage,
          'senderId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

    FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': fabricName,
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

  void _shareFabricDefault(Map<String, dynamic> fabric) {
    final name = fabric['name'] ?? 'Check out this fabric';
    final imageUrl = fabric['imageUrl'] ?? '';
    final description = fabric['description'] ?? '';
    final price = fabric['price'] ?? '';

    final shareText = '$name\nPrice: GHS $price\n\n$description\n\n$imageUrl';

    Share.share(
      shareText.isNotEmpty ? shareText : 'Check out this fabric on FashionHub',
    );
  }
}
