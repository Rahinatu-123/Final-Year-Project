import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'visualize_style.dart';
import 'create_shop_order.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

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
              if (widget.product.type == ProductType.clothes)
                IconButton(
                  icon: const Icon(Icons.checkroom),
                  tooltip: 'Try On',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisualizeStylePage(),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share',
                onPressed: () => _shareProduct(),
              ),
            ],
          ),
          // Main Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel
                if (widget.product.imageUrls.isNotEmpty)
                  _buildImageCarousel()
                else
                  Container(
                    height: 400,
                    width: double.infinity,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(widget.product.name, style: AppTextStyles.h2),
                      const SizedBox(height: 8),

                      // Category
                      if (widget.product.category != null)
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
                            widget.product.category!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Price Section
                      Row(
                        children: [
                          if (widget.product.discountedPrice != null &&
                              widget.product.discountedPrice! > 0 &&
                              widget.product.discountedPrice! <
                                  widget.product.price) ...[
                            Text(
                              'GHS ${widget.product.discountedPrice!.toStringAsFixed(2)}',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GHS ${widget.product.price.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'GHS ${widget.product.price.toStringAsFixed(2)}',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status
                      if (widget.product.isSoldOut)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Specifications for clothes
                      if (widget.product.type == ProductType.clothes) ...[
                        if (widget.product.size != null &&
                            widget.product.size!.isNotEmpty) ...[
                          _buildSpecItem('Size', widget.product.size!),
                          const SizedBox(height: 12),
                        ],
                        if (widget.product.isCustomizable == true)
                          _buildSpecItem('Customizable', 'Yes'),
                      ],

                      // Estimated Delivery Days
                      if (widget.product.estimatedDays != null &&
                          widget.product.estimatedDays! > 0) ...[
                        const SizedBox(height: 12),
                        _buildSpecItem(
                          'Estimated Days to Delivery',
                          '${widget.product.estimatedDays} days',
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Description
                      Text('Description', style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Seller Info
                      Text('Seller', style: AppTextStyles.h4),
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
                                    widget.product.sellerName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.product.type == ProductType.clothes
                                        ? 'Fashion Designer'
                                        : 'Fabric Seller',
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
                      const SizedBox(height: 40),

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 40),

                      // Related Products Section
                      if (widget.product.category != null) ...[
                        Text(
                          'More from this category',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Related Products List
          if (widget.product.category != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('category', isEqualTo: widget.product.category)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final products = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['name'] != widget.product.name;
                    }).toList();

                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Text(
                            'No other products in this category',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final productData =
                            products[index].data() as Map<String, dynamic>;
                        final relatedProduct = Product(
                          id: products[index].id,
                          sellerId: productData['sellerId'] ?? '',
                          sellerName: productData['sellerName'] ?? '',
                          type: productData['type'] == 'ProductType.clothes'
                              ? ProductType.clothes
                              : ProductType.fabric,
                          name: productData['name'] ?? '',
                          description: productData['description'] ?? '',
                          imageUrls: List<String>.from(
                            productData['imageUrls'] ?? [],
                          ),
                          price: (productData['price'] ?? 0).toDouble(),
                          discountedPrice:
                              productData['discountedPrice'] != null
                              ? (productData['discountedPrice']).toDouble()
                              : null,
                          discountPercent: productData['discountPercent'],
                          isSoldOut: productData['isSoldOut'] ?? false,
                          category: productData['category'],
                          color: productData['color'],
                          size: productData['size'],
                          isCustomizable: productData['isCustomizable'],
                          tags: List<String>.from(productData['tags'] ?? []),
                          createdAt: productData['createdAt'] != null
                              ? (productData['createdAt'] as Timestamp).toDate()
                              : DateTime.now(),
                          updatedAt: productData['updatedAt'] != null
                              ? (productData['updatedAt'] as Timestamp).toDate()
                              : DateTime.now(),
                        );

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == products.length - 1 ? 0 : 16,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    product: relatedProduct,
                                  ),
                                ),
                              );
                            },
                            child: _buildRelatedProductCard(relatedProduct),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: widget.product.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.product.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.image_not_supported, size: 64),
                ),
              );
            },
          ),
        ),
        if (widget.product.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.product.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isFabric = widget.product.type == ProductType.fabric;

    if (isFabric) {
      // Fabric: Only Share and Order
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareProduct(),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateShopOrderScreen(
                      product: widget.product,
                      tailorId: widget.product.sellerId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Clothes: Share, Try On, and Order
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareProduct(),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisualizeStylePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.checkroom),
                  label: const Text('Try On'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateShopOrderScreen(
                      product: widget.product,
                      tailorId: widget.product.sellerId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _shareProduct() {
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
                  Text('Share ${widget.product.name}', style: AppTextStyles.h4),
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
                    _buildConnectionsList(currentUser.uid),
                    const SizedBox(height: 24),
                    // Section: Other Share Options
                    _buildOtherShareOptions(),
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

  Widget _buildConnectionsList(String userId) {
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
                          onTap: () => _sendViaChat(connectionUserId, fullName),
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

  Widget _buildOtherShareOptions() {
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
                  _shareProductDefault();
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
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _sendViaChat(String recipientId, String recipientName) async {
    Navigator.pop(context);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final typeStr = widget.product.type == ProductType.clothes
        ? 'Outfit'
        : 'Fabric';
    final price = widget.product.discountedPrice != null
        ? 'GHS ${widget.product.discountedPrice!.toStringAsFixed(2)}'
        : 'GHS ${widget.product.price.toStringAsFixed(2)}';

    final shareText =
        '${widget.product.name}\n$typeStr\nPrice: $price\nBy: ${widget.product.sellerName}\n\n${widget.product.description}';

    final sortedUIDs = [currentUser.uid, recipientId]..sort();
    final chatId = sortedUIDs.join('_');

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'message': shareText,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'text',
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Shared with $recipientName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  void _shareProductDefault() {
    final typeStr = widget.product.type == ProductType.clothes
        ? 'Outfit'
        : 'Fabric';
    final price = widget.product.discountedPrice != null
        ? 'GHS ${widget.product.discountedPrice!.toStringAsFixed(2)}'
        : 'GHS ${widget.product.price.toStringAsFixed(2)}';

    final shareText =
        '${widget.product.name}\n$typeStr\nPrice: $price\nBy: ${widget.product.sellerName}\n\n${widget.product.description}';

    Share.share(shareText);
  }

  Widget _buildRelatedProductCard(Product product) {
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
              product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.image_not_supported, size: 48),
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
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GHS ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }
}
