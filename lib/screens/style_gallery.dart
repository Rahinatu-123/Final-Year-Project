import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StyleGalleryPage extends StatefulWidget {
  const StyleGalleryPage({super.key});

  @override
  State<StyleGalleryPage> createState() => _StyleGalleryPageState();
}

class _StyleGalleryPageState extends State<StyleGalleryPage> {
  int _selectedCategoryIndex = 0;

  final List<String> categories = [
    'All',
    'Traditional',
    'Formal',
    'Casual',
    'Wedding',
    'Kaftan',
    'Dashiki',
  ];

  final List<Map<String, dynamic>> styles = [
    {
      'name': 'Classic Kente',
      'designer': 'Adwoa Designs',
      'image':
          'https://images.pexels.com/photos/1035683/pexels-photo-1035683.jpeg',
      'category': 'Traditional',
      'likes': 234,
    },
    {
      'name': 'Elegant Ankara',
      'designer': 'Fashion Hub',
      'image':
          'https://images.pexels.com/photos/1654648/pexels-photo-1654648.jpeg',
      'category': 'Casual',
      'likes': 189,
    },
    {
      'name': 'Bridal Asoebi',
      'designer': 'Royal Stitches',
      'image':
          'https://images.pexels.com/photos/984619/pexels-photo-984619.jpeg',
      'category': 'Wedding',
      'likes': 456,
    },
    {
      'name': 'Modern Dashiki',
      'designer': 'African Roots',
      'image':
          'https://images.pexels.com/photos/375810/pexels-photo-375810.jpeg',
      'category': 'Casual',
      'likes': 312,
    },
    {
      'name': 'Formal Kaftan',
      'designer': 'Design House',
      'image':
          'https://images.pexels.com/photos/1755428/pexels-photo-1755428.jpeg',
      'category': 'Formal',
      'likes': 278,
    },
    {
      'name': 'Lace Asoebi',
      'designer': 'Lace & Pearls',
      'image':
          'https://images.pexels.com/photos/1413420/pexels-photo-1413420.jpeg',
      'category': 'Wedding',
      'likes': 421,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Style Gallery",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(child: _buildStyleGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              alignment: Alignment.center,
              child: Text(
                categories[index],
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

  Widget _buildStyleGrid() {
    final filteredStyles = _selectedCategoryIndex == 0
        ? styles
        : styles
              .where((s) => s['category'] == categories[_selectedCategoryIndex])
              .toList();

    if (filteredStyles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              "No styles in this category yet",
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredStyles.length,
      itemBuilder: (context, index) {
        return _buildStyleCard(filteredStyles[index]);
      },
    );
  }

  Widget _buildStyleCard(Map<String, dynamic> style) {
    return GestureDetector(
      onTap: () => _showStyleDetail(style),
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
                style['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.image_not_supported),
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
                        style['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        style['designer'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${style['likes']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
      ),
    );
  }

  void _showStyleDetail(Map<String, dynamic> style) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  style['image'],
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style['name'], style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(
                      "by ${style['designer']}",
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Try On feature coming soon!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.checkroom, size: 20),
                        label: const Text("Try On This Style"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
