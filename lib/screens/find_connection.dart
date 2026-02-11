import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'user_profile_view.dart';

class FindConnectionPage extends StatefulWidget {
  const FindConnectionPage({super.key});

  @override
  State<FindConnectionPage> createState() => _FindConnectionPageState();
}

class _FindConnectionPageState extends State<FindConnectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Future<List<Map<String, dynamic>>>? _initialUsersFuture;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      QuerySnapshot snapshot;

      // Search across users collection by username prefix
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .limit(20)
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return {
            'uid': doc.id,
            'name': (data?['username'] ?? 'Unknown') as String,
            'email': (data?['email'] ?? '') as String,
            'role': (data?['role'] ?? 'user') as String,
            'profileImage': (data?['profileImage'] ?? '') as String,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Search error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInitialUsers() async {
    final current = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return {
            'uid': doc.id,
            'name':
                (data?['username'] ?? data?['fullName'] ?? 'Unknown') as String,
            'email': (data?['email'] ?? '') as String,
            'role': (data?['role'] ?? 'user') as String,
            'profileImage': (data?['profileImage'] ?? '') as String,
          };
        })
        .where((m) => m['uid'] != current?.uid)
        .toList();
  }

  Future<void> _connectWithUser(
    String targetUserId,
    String targetUserName,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final connectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('connections')
          .doc(targetUserId);

      final targetFollowerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid);

      await connectionRef.set({
        'userId': targetUserId,
        'userName': targetUserName,
        'connectedAt': FieldValue.serverTimestamp(),
      });

      // Add reciprocal follower doc and increment counts
      await targetFollowerRef.set({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? '',
        'connectedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .update({'followersCount': FieldValue.increment(1)});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'followingCount': FieldValue.increment(1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected with $targetUserName!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error connecting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Find Connection', style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed role selector — simple search UI below

              // Search Bar
              Text(
                'Search name',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: AppColors.surfaceVariant, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter name...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          _performSearch(_searchController.text.trim()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Results
              if (_isSearching)
                Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_searchResults.isEmpty &&
                  _searchController.text.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No results found',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results (${_searchResults.length})',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _buildUserResultCard(user);
                      },
                    ),
                  ],
                )
              else if (_searchController.text.isEmpty)
                // When search is empty show recent users (like contacts)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _initialUsersFuture ??= _fetchInitialUsers(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    final users = snap.data ?? [];
                    if (users.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No users found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contacts',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _buildUserResultCard(user);
                          },
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserResultCard(Map<String, dynamic> user) {
    final roleLabel = _getRoleLabel(user['role']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          // Profile Image or Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child:
                user['profileImage'] != null && user['profileImage'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    child: Image.network(
                      user['profileImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, color: AppColors.primary);
                      },
                    ),
                  )
                : Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                  child: Text(
                    roleLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'connect') {
                _connectWithUser(user['uid'], user['name']);
              } else if (value == 'profile') {
                // Navigate to profile view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(uid: user['uid']),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'connect',
                child: Row(
                  children: [
                    const Icon(Icons.person_add),
                    const SizedBox(width: 8),
                    const Text('Connect'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    const Text('View Profile'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(Icons.more_vert, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'tailor':
        return 'Tailor';
      case 'fabric_seller':
        return 'Fabric Seller';
      default:
        return 'User';
    }
  }
}
