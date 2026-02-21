import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'visualize_style.dart';

class ProductPreviewScreen extends StatefulWidget {
  final String name;
  final String description;
  final double price;
  final double? discountedPrice;
  final String? color;
  final String? size;
  final ProductType type;
  final String? category;
  final bool isSoldOut;
  final bool isCustomizable;
  final List<String> imageUrls;
  final List<String> selectedImagePaths;
  final String sellerId;
  final VoidCallback onConfirm;

  const ProductPreviewScreen({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    this.color,
    this.size,
    required this.type,
    this.category,
    required this.isSoldOut,
    required this.isCustomizable,
    required this.imageUrls,
    required this.selectedImagePaths,
    required this.sellerId,
    required this.onConfirm,
  });

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allImages = [...widget.imageUrls, ...widget.selectedImagePaths];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (allImages.isNotEmpty)
              _buildImageCarousel(allImages)
            else
              Container(
                height: 400,
                width: double.infinity,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.image_not_supported, size: 64),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(widget.name, style: AppTextStyles.h2),
                  const SizedBox(height: 8),

                  // Category Badge
                  if (widget.category != null)
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
                        widget.category!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Price Section
                  Row(
                    children: [
                      Text(
                        'GHS ${widget.price.toStringAsFixed(2)}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (widget.discountedPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'GHS ${widget.discountedPrice!.toStringAsFixed(2)}',
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
                  if (widget.isSoldOut)
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

                  // Specifications
                  if (widget.type == ProductType.clothes) ...[
                    if (widget.color != null && widget.color!.isNotEmpty) ...[
                      _buildSpecItem('Color', widget.color!),
                      const SizedBox(height: 12),
                    ],
                    if (widget.size != null && widget.size!.isNotEmpty) ...[
                      _buildSpecItem('Size', widget.size!),
                      const SizedBox(height: 12),
                    ],
                    if (widget.isCustomizable)
                      _buildSpecItem('Customizable', 'Yes'),
                  ],

                  const SizedBox(height: 20),

                  // Description
                  Text('Description', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  // Post Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Post to Shop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];

              // Check if it's a local file path or a network URL
              if (image.startsWith('http://') || image.startsWith('https://')) {
                // Network image
                return Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                );
              } else {
                // Local file image
                return Image.file(
                  File(image),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                );
              }
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
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
    final isFabric = widget.type == ProductType.fabric;

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
    final typeStr = widget.type == ProductType.clothes ? 'Outfit' : 'Fabric';
    final price = widget.discountedPrice != null
        ? 'GHS ${widget.discountedPrice!.toStringAsFixed(2)}'
        : 'GHS ${widget.price.toStringAsFixed(2)}';

    final shareText =
        '${widget.name}\n$typeStr\nPrice: $price\n\n${widget.description}';

    Share.share(shareText);
  }
}
