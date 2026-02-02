import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'create_post_screen.dart';
import 'customer_dashboard.dart';
import 'profile_customer.dart';
import 'explore.dart';

class UniversalHome extends StatefulWidget {
  const UniversalHome({super.key});

  @override
  State<UniversalHome> createState() => _UniversalHomeState();
}

class _UniversalHomeState extends State<UniversalHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeFeedPage(),
    const ExplorePage(),
    const CustomerDashboard(),
    const CustomerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _currentIndex == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          children: const [
            TextSpan(
              text: 'Fashion',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(
              text: 'Hub',
              style: TextStyle(color: AppColors.secondary),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
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
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        shape: BoxShape.circle,
        boxShadow: AppShadows.colored(AppColors.coral),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, "Feed"),
              _buildNavItem(
                1,
                Icons.explore_rounded,
                Icons.explore_outlined,
                "Explore",
              ),
              _buildNavItem(
                2,
                Icons.grid_view_rounded,
                Icons.grid_view_outlined,
                "Dashboard",
              ),
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_outline,
                "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- THE HOME FEED PAGE ---
class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  void _toggleLike(String postId, List likes) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    DocumentReference postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId);

    if (likes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildTopTailors(),
          const SizedBox(height: 20),
          _buildCategories(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Latest Inspiration", style: AppTextStyles.h4),
          ),
          _buildGlobalFeed(),
        ],
      ),
    );
  }

  Widget _buildTopTailors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Top Tailors", style: AppTextStyles.h4),
              TextButton(
                onPressed: () {},
                child: Text(
                  "See All",
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?u=tailor$index',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tailor ${index + 1}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final cats = ["All", "Traditional", "Bridal", "Suits", "Lace", "Casual"];
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: index == 0 ? AppColors.warmGradient : null,
              color: index == 0 ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              boxShadow: index == 0
                  ? AppShadows.colored(AppColors.coral)
                  : AppShadows.soft,
            ),
            alignment: Alignment.center,
            child: Text(
              cats[index],
              style: AppTextStyles.labelMedium.copyWith(
                color: index == 0 ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFeed() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyFeed();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var post = doc.data() as Map<String, dynamic>;
            List likes = post['likes'] ?? [];
            bool isLiked = likes.contains(currentUserId);

            return _buildPostCard(doc.id, post, likes, isLiked);
          },
        );
      },
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              "No posts yet",
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to share your fashion inspiration!",
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(
    String docId,
    Map<String, dynamic> post,
    List likes,
    bool isLiked,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.person, color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] ?? "Designer",
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.xs,
                          ),
                        ),
                        child: Text(
                          post['userType'] ?? "Fashion Hub",
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Image
          ClipRRect(
            child: Image.network(
              (post['mediaUrls'] as List?)?.isNotEmpty == true
                  ? post['mediaUrls'][0]
                  : '',
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 350,
                  color: AppColors.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Image load error: $error');
                debugPrint('Image URL: ${post['mediaUrls']?[0]}');
                return Container(
                  height: 350,
                  color: AppColors.surfaceVariant,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image unavailable',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.coral : AppColors.textPrimary,
                      count: likes.length,
                      onTap: () => _toggleLike(docId, likes),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.textPrimary,
                      count: 0,
                      onTap: () {},
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.send_outlined,
                      color: AppColors.textPrimary,
                      onTap: () {},
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_border,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: "${post['userName']} ",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post['content'] ?? ""),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
