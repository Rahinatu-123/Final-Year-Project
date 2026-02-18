import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'style_gallery.dart';
import 'fabric_gallery.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> categoryFilters = ['All', 'Styles', 'Fabrics'];

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Bridal',
      'icon': Icons.favorite,
      'firestoreCategories': ['bridal kenta', 'lace'],
    },
    {
      'name': 'Traditional',
      'icon': Icons.star,
      'firestoreCategories': ['kaba and slit', 'bridal kenta', 'traditional'],
    },
    {
      'name': 'Men',
      'icon': Icons.man,
      'firestoreCategories': ['men'],
    },
    {
      'name': 'Lace',
      'icon': Icons.auto_awesome,
      'firestoreCategories': ['lace'],
    },
    {
      'name': 'Simple Wear',
      'icon': Icons.checkroom,
      'firestoreCategories': ['short dress', 'long dress', 'jumpsuit'],
    },
    {
      'name': 'Fabric',
      'icon': Icons.texture,
      'firestoreCategories': ['fabric'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryTabs(),
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
        children: [Text("Explore", style: AppTextStyles.h2)],
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
            hintText: "Search styles, tailors, fabrics...",
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
              print('Tab clicked: $index, filter: ${categoryFilters[index]}');
              setState(() => _selectedCategoryIndex = index);
              print('Updated index: $_selectedCategoryIndex');

              // Navigate to Styles when Styles tab is clicked
              if (categoryFilters[index] == 'Styles') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StyleGalleryPage(
                      title: "All Styles",
                      categories: [],
                    ),
                  ),
                );
              }

              // Navigate to Fabrics when Fabrics tab is clicked
              if (categoryFilters[index] == 'Fabrics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FabricGalleryPage(
                      title: "All Fabrics",
                      categories: [],
                    ),
                  ),
                );
              }
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

  Widget _buildCategoryGrid() {
    String selectedFilter = categoryFilters[_selectedCategoryIndex];
    print('Selected filter: $selectedFilter, index: $_selectedCategoryIndex');

    // Show all content (styles + fabrics) for 'All'
    if (selectedFilter == 'All') {
      print('Showing all content');
      return _buildAllContentGrid();
    } else {
      // Show filtered content for Styles and Fabrics
      print('Showing content grid for: $selectedFilter');
      return _buildContentGrid(selectedFilter);
    }
  }

  Widget _buildAllContentGrid() {
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('styles').get(),
        FirebaseFirestore.instance.collection('fabrics').get(),
      ]),
      builder: (context, snapshot) {
        print('FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error in FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text("Error loading data: ${snapshot.error}"),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          print('No data in snapshot');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style, size: 64),
                const SizedBox(height: 16),
                Text("No styles or fabrics found"),
              ],
            ),
          );
        }

        try {
          // Check each result individually
          final stylesResult = snapshot.data![0];
          final fabricsResult = snapshot.data![1];

          final styles = stylesResult.docs;
          final fabrics = fabricsResult.docs;
          print('Styles count: ${styles.length}');
          print('Fabrics count: ${fabrics.length}');

          final allItems = [
            ...styles.map((doc) => {'data': doc.data(), 'type': 'Styles'}),
            ...fabrics.map((doc) => {'data': doc.data(), 'type': 'Fabrics'}),
          ];

          // Randomize the order of items
          allItems.shuffle();

          // Apply search filter
          String searchTerm = _searchController.text.toLowerCase().trim();
          List<Map<String, dynamic>> filteredItems = allItems;

          if (searchTerm.isNotEmpty) {
            filteredItems = allItems.where((item) {
              final data = item['data'] as Map<String, dynamic>;
              final name = (data['name'] as String? ?? '').toLowerCase();
              final description = (data['description'] as String? ?? '')
                  .toLowerCase();
              final category = (data['category'] as String? ?? '')
                  .toLowerCase();

              return name.contains(searchTerm) ||
                  description.contains(searchTerm) ||
                  category.contains(searchTerm);
            }).toList();
          }

          print('Total items: ${filteredItems.length}');

          if (filteredItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style, size: 64),
                  const SizedBox(height: 16),
                  Text("No styles or fabrics found"),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildContentCard(
                item['data'] as Map<String, dynamic>,
                item['type'] as String,
              );
            },
          );
        } catch (e) {
          print('Error processing data: $e');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text("Error processing data: $e"),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        // Navigate to StyleGallery with the specific category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StyleGalleryPage(
              title: category['name'],
              categories: List<String>.from(category['firestoreCategories']),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.medium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('styles')
                    .where(
                      'category',
                      whereIn: category['firestoreCategories'] as List<String>,
                    )
                    .limit(1)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final imageUrl = snapshot.data!.docs.first['imageUrl'];
                    return Image.network(imageUrl, fit: BoxFit.cover);
                  }
                  return Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  );
                },
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.85),
                    ],
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
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(category['icon'], color: Colors.white),
                    ),
                    Text(
                      category['name'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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

  Widget _buildContentGrid(String filter) {
    Query query;

    if (filter == 'Styles') {
      query = FirebaseFirestore.instance.collection('styles');
    } else if (filter == 'Fabrics') {
      query = FirebaseFirestore.instance.collection('fabrics');
    } else {
      query = FirebaseFirestore.instance.collection('styles');
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
                Icon(
                  filter == 'Fabrics' ? Icons.texture : Icons.style,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text("No ${filter.toLowerCase()} found"),
              ],
            ),
          );
        }

        final items = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index].data() as Map<String, dynamic>;
            return _buildContentCard(item, filter);
          },
        );
      },
    );
  }

  Widget _buildContentCard(Map<String, dynamic> item, String type) {
    return GestureDetector(
      onTap: () {
        if (type == 'Styles') {
          _showStyleDetail(item);
        } else if (type == 'Fabrics') {
          _showFabricDetail(item);
        }
      },
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
                item['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: Icon(
                    type == 'Fabrics' ? Icons.texture : Icons.style,
                    size: 48,
                  ),
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
                        item['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item['description'] != null)
                        Text(
                          item['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
          child: SingleChildScrollView(
            controller: scrollController,
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
                    style['imageUrl'] ?? '',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(style['name'] ?? '', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      Text(style['description'] ?? ''),
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
      ),
    );
  }

  void _showFabricDetail(Map<String, dynamic> fabric) {
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
          child: SingleChildScrollView(
            controller: scrollController,
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
                    fabric['imageUrl'] ?? '',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fabric['name'] ?? '', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      Text(fabric['description'] ?? ''),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Order this fabric coming soon!"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag, size: 20),
                          label: const Text("Order This Fabric"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
