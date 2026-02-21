import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'visualize_style.dart';

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
                          Text(
                            'GHS ${widget.product.price.toStringAsFixed(2)}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          if (widget.product.discountedPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'GHS ${widget.product.discountedPrice!.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textTertiary,
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
                        if (widget.product.color != null &&
                            widget.product.color!.isNotEmpty) ...[
                          _buildSpecItem('Color', widget.product.color!),
                          const SizedBox(height: 12),
                        ],
                        if (widget.product.size != null &&
                            widget.product.size!.isNotEmpty) ...[
                          _buildSpecItem('Size', widget.product.size!),
                          const SizedBox(height: 12),
                        ],
                        if (widget.product.isCustomizable == true)
                          _buildSpecItem('Customizable', 'Yes'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order functionality coming soon!'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order functionality coming soon!'),
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
