import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import 'style_gallery.dart';
import 'fabric_gallery.dart';
import 'shop_gallery.dart';
import 'chat.dart';
import 'style_detail_page.dart';

class ExplorePage extends StatefulWidget {
  final bool filterByProfessionals;

  const ExplorePage({super.key, this.filterByProfessionals = false});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> categoryFilters = ['All', 'Styles', 'Fabrics', 'Shop'];

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
            if (!widget.filterByProfessionals) ...[
              _buildSearchBar(),
              _buildCategoryTabs(),
            ],
            Expanded(
              child: widget.filterByProfessionals
                  ? _buildProfessionalsGrid()
                  : _buildCategoryGrid(),
            ),
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
          if (widget.filterByProfessionals)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back),
            ),
          Text(
            widget.filterByProfessionals ? "Find Connections" : "Explore",
            style: AppTextStyles.h2,
          ),
          if (widget.filterByProfessionals)
            const SizedBox(width: 40), // Balance the back button
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

              // Navigate to Shop when Shop tab is clicked
              if (categoryFilters[index] == 'Shop') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopGalleryPage(),
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

  Widget _buildProfessionalsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text("Error loading professionals: ${snapshot.error}"),
              ],
            ),
          );
        }

        // Filter users where role is not 'customer'
        final professionals = (snapshot.data?.docs ?? []).where((doc) {
          final role =
              (doc.data() as Map<String, dynamic>)['role'] ?? 'customer';
          return role.toString().toLowerCase() != 'customer';
        }).toList();

        if (professionals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 64),
                const SizedBox(height: 16),
                const Text("No tailors or fabric sellers found"),
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
            mainAxisSpacing: 16,
          ),
          itemCount: professionals.length,
          itemBuilder: (context, index) {
            final professional =
                professionals[index].data() as Map<String, dynamic>;
            final name =
                (professional['name'] ?? '').toString().trim().isNotEmpty
                ? professional['name']
                : (professional['firstName'] ?? 'User');
            final profileImage = professional['profileImage'] ?? '';
            final role = professional['role'] ?? 'tailor';
            final uid = professionals[index].id;
            final businessName = professional['businessName'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/profile', arguments: uid);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          image: profileImage.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(profileImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.surfaceVariant,
                        ),
                        child: profileImage.isEmpty
                            ? Center(
                                child: CircleAvatar(
                                  radius: 40,
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.toLowerCase().contains('tailor')
                                ? 'Tailor'
                                : role.toLowerCase().contains('seamstress')
                                ? 'Seamstress'
                                : 'Fabric Seller',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (businessName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
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
          },
        );
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
                future: category['name'] == 'Fabric'
                    ? FirebaseFirestore.instance
                          .collection('fabrics')
                          .where(
                            'category',
                            whereIn:
                                category['firestoreCategories'] as List<String>,
                          )
                          .limit(1)
                          .get()
                    : FirebaseFirestore.instance
                          .collection('styles')
                          .where(
                            'category',
                            whereIn:
                                category['firestoreCategories'] as List<String>,
                          )
                          .limit(1)
                          .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final doc = snapshot.data!.docs.first;
                    final imageUrl = category['name'] == 'Fabric'
                        ? (doc['imageUrls'] as List?)?.first ?? ''
                        : doc['imageUrl'] ?? '';
                    if (imageUrl.isNotEmpty) {
                      return Image.network(imageUrl, fit: BoxFit.cover);
                    }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StyleDetailPage(
          style: style,
          category: style['category'],
          styleId: style['id'], // Pass the document ID
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
                      if (fabric['price'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'GHS ${fabric['price']}',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (fabric['sellerId'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.store,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Seller',
                                      style: AppTextStyles.labelSmall,
                                    ),
                                    Text(
                                      fabric['sellerName'] ?? 'Fabric Seller',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareFabric(fabric);
                          },
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text("Share"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
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

  void _shareStyle(Map<String, dynamic> style) {
    _showStyleShareDialog(style);
  }

  void _showStyleShareDialog(Map<String, dynamic> style) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.8,
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
                    _buildExploreStyleConnectionsList(currentUser.uid, style),
                    const SizedBox(height: 24),
                    // Section: Other Share Options (no label)
                    _buildExploreStyleOtherShareOptions(style),
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

  Widget _buildExploreStyleConnectionsList(
    String userId,
    Map<String, dynamic> style,
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
                          onTap: () => _sendStyleViaChat(
                            connectionUserId,
                            fullName,
                            style,
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

  Widget _buildExploreStyleOtherShareOptions(Map<String, dynamic> style) {
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

  void _sendStyleViaChat(
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

    // Send as structured style message so chat can render the style card.
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

    final shareText = '$name\n\n$description\n\n$imageUrl';

    Share.share(
      shareText.isNotEmpty ? shareText : 'Check out this style on FashionHub',
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
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  _buildExploreConnectionsList(currentUser.uid, fabric),
                  const SizedBox(height: 24),
                  // Section: Other Share Options
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Other Options',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _buildExploreOtherShareOptions(fabric),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreConnectionsList(
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
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
                              : const Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        // Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                connectionName,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Send Button
                        ElevatedButton.icon(
                          onPressed: () => _sendExploreViaChat(
                            connectionUserId,
                            fullName,
                            fabric,
                          ),
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Send'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExploreOtherShareOptions(Map<String, dynamic> fabric) {
    final shareOptions = [
      {
        'icon': Icons.share,
        'label': 'Share via WhatsApp',
        'color': const Color(0xFF25D366),
      },
      {
        'icon': Icons.share,
        'label': 'Share via Instagram',
        'color': const Color(0xFFE4405F),
      },
      {
        'icon': Icons.mail,
        'label': 'Share via Email',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.more_horiz,
        'label': 'More Options',
        'color': AppColors.textSecondary,
      },
    ];

    return Column(
      children: shareOptions
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: ListTile(
                  leading: Icon(
                    option['icon'] as IconData,
                    color: option['color'] as Color,
                  ),
                  title: Text(
                    option['label'] as String,
                    style: AppTextStyles.bodyMedium,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    if (option['label'] == 'More Options') {
                      _shareFabricDefault(fabric);
                    }
                  },
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _sendExploreViaChat(
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
    final price = fabric['price'] ?? '';

    final shareText = '$name\nPrice: GHS $price\n\n$imageUrl';

    Share.share(
      shareText.isNotEmpty ? shareText : 'Check out this fabric on FashionHub',
    );
  }

  Future<void> _orderStyle(Map<String, dynamic> style) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    final sellerId = style['sellerId'];
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller information not available')),
      );
      return;
    }

    final sellerName = style['sellerName'] ?? 'Style Creator';
    final styleName = style['name'] ?? 'Style';

    // Create or get existing chat
    try {
      final existingChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? chatId;
      for (final doc in existingChats.docs) {
        final participants = doc['participants'] as List<dynamic>? ?? [];
        if (participants.contains(sellerId)) {
          chatId = doc.id;
          break;
        }
      }

      if (chatId == null) {
        // Create new chat
        final newChat = await FirebaseFirestore.instance
            .collection('chats')
            .add({
              'participants': [currentUser.uid, sellerId],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'lastMessage': 'Hey! I\'m interested in: $styleName',
              'unreadCount': {currentUser.uid: 0, sellerId: 0},
            });
        chatId = newChat.id;

        // Add initial message
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
              'text':
                  'Hey! I\'m interested in: $styleName. Can we discuss details about ordering?',
              'senderId': currentUser.uid,
              'senderName': currentUser.displayName ?? 'User',
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatId: chatId!, otherUserName: sellerName),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  Future<void> _orderFabric(Map<String, dynamic> fabric) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    final sellerId = fabric['sellerId'];
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller information not available')),
      );
      return;
    }

    final sellerName = fabric['sellerName'] ?? 'Fabric Seller';
    final fabricName = fabric['name'] ?? 'Fabric';

    // Create or get existing chat
    try {
      final existingChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? chatId;
      for (final doc in existingChats.docs) {
        final participants = doc['participants'] as List<dynamic>? ?? [];
        if (participants.contains(sellerId)) {
          chatId = doc.id;
          break;
        }
      }

      if (chatId == null) {
        // Create new chat
        final newChat = await FirebaseFirestore.instance
            .collection('chats')
            .add({
              'participants': [currentUser.uid, sellerId],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'lastMessage': 'Hey! I\'m interested in: $fabricName',
              'unreadCount': {currentUser.uid: 0, sellerId: 0},
            });
        chatId = newChat.id;

        // Add initial message
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
              'text':
                  'Hey! I\'m interested in: $fabricName. Can you tell me more about this fabric and pricing?',
              'senderId': currentUser.uid,
              'senderName': currentUser.displayName ?? 'User',
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatId: chatId!, otherUserName: sellerName),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
