import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class ShopGalleryPage extends StatefulWidget {
  const ShopGalleryPage({super.key});

  @override
  State<ShopGalleryPage> createState() => _ShopGalleryPageState();
}

class _ShopGalleryPageState extends State<ShopGalleryPage> {
  late ProductService productService;
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> categoryFilters = ['All', 'Clothes', 'Fabric'];

  @override
  void initState() {
    super.initState();
    productService = ProductService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(child: _buildProductsGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {}); // Trigger rebuild when search changes
          },
          decoration: InputDecoration(
            hintText: "Search products, sellers...",
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categoryFilters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
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
                categoryFilters[index],
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

  Widget _buildProductsGrid() {
    String selectedFilter = categoryFilters[_selectedCategoryIndex];
    String searchQuery = _searchController.text.toLowerCase();

    return StreamBuilder<List<Product>>(
      stream: _getFilteredProductsStream(selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        List<Product> products = snapshot.data ?? [];

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          products = products
              .where(
                (product) =>
                    product.name.toLowerCase().contains(searchQuery) ||
                    product.sellerName.toLowerCase().contains(searchQuery) ||
                    product.description.toLowerCase().contains(searchQuery),
              )
              .toList();
        }

        // Filter out sold out items (optional - you can show them with a badge)
        List<Product> availableProducts = products
            .where((p) => !p.isSoldOut)
            .toList();
        List<Product> soldOutProducts = products
            .where((p) => p.isSoldOut)
            .toList();

        // Show available first, then sold out
        final displayProducts = [...availableProducts, ...soldOutProducts];

        if (displayProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(displayProducts[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details (optional - can be implemented later)
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: AppColors.surfaceVariant,
                    image: product.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrls.isEmpty
                      ? const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textTertiary,
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${product.sellerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!product.isSoldOut)
                          if (product.discountedPrice != null)
                            Row(
                              children: [
                                Text(
                                  'GHS ${product.discountedPrice!.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'GHS ${product.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'GHS ${product.price.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Sold Out Badge
            if (product.isSoldOut)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            if (product.isSoldOut)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Sold Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Discount Badge
            if (product.discountPercent != null && product.discountPercent! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${product.discountPercent!.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Stream<List<Product>> _getFilteredProductsStream(String filter) {
    try {
      if (filter == 'All') {
        return productService.getAllProductsStream();
      } else if (filter == 'Clothes') {
        return productService.getProductsByTypeStream(ProductType.clothes);
      } else if (filter == 'Fabric') {
        return productService.getProductsByTypeStream(ProductType.fabric);
      }
      return Stream.value([]);
    } catch (e) {
      return Stream.error('Failed to load products: $e');
    }
  }

  Future<List<Product>> _getFilteredProducts(String filter) async {
    try {
      if (filter == 'All') {
        return await productService.getAllProducts();
      } else if (filter == 'Clothes') {
        return await productService.getProductsByType(ProductType.clothes);
      } else if (filter == 'Fabric') {
        return await productService.getProductsByType(ProductType.fabric);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
