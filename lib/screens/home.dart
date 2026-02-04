import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
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

  void _sharePost(Map<String, dynamic> post) {
    final media = (post['mediaUrls'] as List?)?.cast<String>() ?? [];
    final content = post['content'] ?? '';
    final url = media.isNotEmpty ? media.first : '';
    final text = content.isNotEmpty ? '$content\n$url' : url;
    if (text.isNotEmpty) Share.share(text);
  }

  void _showComments(String postId, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final TextEditingController _commentController =
            TextEditingController();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Comments', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final docs = snap.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, idx) {
                          final c = docs[idx].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(c['authorName'] ?? 'User'),
                            subtitle: Text(c['text'] ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          final user = FirebaseAuth.instance.currentUser;
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .add({
                                'text': text,
                                'authorId': user?.uid,
                                'authorName': user?.displayName ?? 'User',
                                'createdAt': Timestamp.now(),
                              });

                          // increment commentCount on post
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .update({
                                'commentCount': FieldValue.increment(1),
                              });

                          _commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  late Map<String, int> _carouselIndices = {};

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
                  onPressed: () => _showPostMenu(post, docId),
                ),
              ],
            ),
          ),

          // Image carousel
          _buildImageCarousel(post),

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
                      count: post['commentCount'] ?? 0,
                      onTap: () => _showComments(docId, post),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.send_outlined,
                      color: AppColors.textPrimary,
                      onTap: () => _sharePost(post),
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

  Widget _buildImageCarousel(Map<String, dynamic> post) {
    final mediaUrls = (post['mediaUrls'] as List?)?.cast<String>() ?? [];
    final postId = post['userId'];

    if (mediaUrls.isEmpty) {
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
    }

    return Stack(
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                _carouselIndices[postId] = index;
              });
            },
            itemCount: mediaUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                child: Image.network(
                  mediaUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 350,
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
              );
            },
          ),
        ),
        // Image counter badge (only show if multiple images)
        if (mediaUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                '${(_carouselIndices[postId] ?? 0) + 1}/${mediaUrls.length}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
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

  void _showPostMenu(Map<String, dynamic> post, String postId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final postUserId = post['userId'];
    final isPostOwner = currentUserId == postUserId;

    if (!isPostOwner) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(postId);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Delete Post',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text(
          'Delete Post',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _deletePost(postId);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete post'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
        ),
      );
    }
  }

  // Show comments dialog for a post and allow adding a new comment
  void _showComments(String postId, Map<String, dynamic> post) {
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments', style: AppTextStyles.h4),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error loading comments'));
                    }
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    if (docs.isEmpty)
                      return Center(child: Text('No comments yet'));
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, idx) {
                        final c = docs[idx].data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          title: Text(
                            c['authorName'] ?? 'User',
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(c['content'] ?? ''),
                          trailing: Text(
                            c['createdAt'] != null
                                ? _formatRelativeTime(
                                    (c['createdAt'] as Timestamp).toDate(),
                                  )
                                : '',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () async {
                      final text = _commentController.text.trim();
                      if (text.isEmpty) return;
                      final user = FirebaseAuth.instance.currentUser;
                      final commentRef = FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .doc();
                      await commentRef.set({
                        'authorId': user?.uid,
                        'authorName': user?.displayName ?? 'User',
                        'content': text,
                        'createdAt': Timestamp.now(),
                      });
                      // increment commentCount on post doc
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({'commentCount': FieldValue.increment(1)});
                      _commentController.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Share a post using share_plus (shares text + first media URL if available)
  void _sharePost(Map<String, dynamic> post) {
    final content = post['content'] ?? '';
    final media = (post['mediaUrls'] as List?)?.cast<String>() ?? [];
    final url = media.isNotEmpty ? media.first : null;
    final shareText = url != null ? '$content\n\n$url' : content;
    try {
      Share.share(shareText.isNotEmpty ? shareText : 'Check out this post');
    } catch (e) {
      debugPrint('Share failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to share post')));
    }
  }
}
