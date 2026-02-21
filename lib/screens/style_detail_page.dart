import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import 'visualize_style.dart';

class StyleDetailPage extends StatefulWidget {
  final Map<String, dynamic> style;
  final String? category;
  final String? styleId; // Add document ID

  const StyleDetailPage({
    super.key,
    required this.style,
    this.category,
    this.styleId,
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
                onPressed: () => _shareStyle(widget.style),
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
                    errorBuilder: (_, __, ___) => Container(
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
                            color: AppColors.primary.withOpacity(0.1),
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const VisualizeStylePage(),
                                  ),
                                );
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

    print('DEBUG: Attempting to find related styles');
    print('DEBUG: Category value: "$category"');
    print('DEBUG: Current Style ID: "$currentStyleId"');
    print('DEBUG: Current style name: ${widget.style['name']}');

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
        print('DEBUG: StreamBuilder state - ${snapshot.connectionState}');
        if (!snapshot.hasData) {
          print('DEBUG: No data in snapshot');
          return const Center(child: CircularProgressIndicator());
        }

        print('DEBUG: Snapshot has ${snapshot.data!.docs.length} documents');

        // Filter out the current style using document ID (more reliable)
        final styles = snapshot.data!.docs.where((doc) {
          final docId = doc.id;
          final isCurrentStyle =
              currentStyleId != null && docId == currentStyleId;
          print('DEBUG: Doc ID: $docId, is current: $isCurrentStyle');
          return !isCurrentStyle;
        }).toList();

        print('DEBUG: After filtering by ID: ${styles.length} styles found');

        if (styles.isEmpty) {
          // If filtering by ID found nothing, try filtering by name as fallback
          print('DEBUG: No styles after ID filter, trying name filter...');
          final stylesByName = snapshot.data!.docs.where((doc) {
            final docData = doc.data() as Map<String, dynamic>;
            return docData['name'] != widget.style['name'];
          }).toList();

          print(
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
              Navigator.pushReplacement(
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
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.style, size: 48),
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
                          color: Colors.white.withOpacity(0.8),
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
    final name = style['name'] ?? 'Check out this style';
    final imageUrl = style['imageUrl'] ?? '';
    final description = style['description'] ?? '';
    final sellerName = style['sellerName'] ?? '';

    final shareText = '$name\nBy $sellerName\n\n$description\n\n$imageUrl';

    Share.share(
      shareText.isNotEmpty ? shareText : 'Check out this style on FashionHub',
    );
  }
}
