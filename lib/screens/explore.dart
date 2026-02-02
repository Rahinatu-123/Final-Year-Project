import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> categories = const [
    {
      'name': 'Bridal',
      'icon': Icons.favorite,
      'image':
          'https://images.pexels.com/photos/1035683/pexels-photo-1035683.jpeg',
    },
    {
      'name': 'Traditional',
      'icon': Icons.star,
      'image':
          'https://images.pexels.com/photos/1654648/pexels-photo-1654648.jpeg',
    },
    {
      'name': 'Suits',
      'icon': Icons.business_center,
      'image':
          'https://images.pexels.com/photos/375810/pexels-photo-375810.jpeg',
    },
    {
      'name': 'Lace & Asoebi',
      'icon': Icons.auto_awesome,
      'image':
          'https://images.pexels.com/photos/984619/pexels-photo-984619.jpeg',
    },
    {
      'name': 'Evening Wear',
      'icon': Icons.nightlife,
      'image':
          'https://images.pexels.com/photos/1755428/pexels-photo-1755428.jpeg',
    },
    {
      'name': 'Accessories',
      'icon': Icons.diamond,
      'image':
          'https://images.pexels.com/photos/1413420/pexels-photo-1413420.jpeg',
    },
  ];

  final List<String> categoryFilters = [
    'All',
    'Styles',
    'Tailors',
    'Fabrics',
    'Trends',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categoryFilters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),

            // Search Bar
            _buildSearchBar(),

            // Category Tabs
            _buildCategoryTabs(),

            // Category Grid
            Expanded(child: _buildCategoryGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Explore", style: AppTextStyles.h2),
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
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  boxShadow: AppShadows.soft,
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: "Search styles, tailors, fabrics...",
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 24,
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            border: InputBorder.none,
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
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categoryFilters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.warmGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: isSelected
                    ? AppShadows.colored(AppColors.coral)
                    : AppShadows.soft,
              ),
              alignment: Alignment.center,
              child: Text(
                categoryFilters[index],
                style: AppTextStyles.labelMedium.copyWith(
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

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(categories[index], index);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to category detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: AppShadows.medium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                category['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Favorite button
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                    // Category info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'].toString().toUpperCase(),
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.xl,
                            ),
                          ),
                          child: Text(
                            "${(index + 1) * 24} items",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
