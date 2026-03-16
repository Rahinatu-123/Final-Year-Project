import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class UserProfilePage extends StatefulWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _tailorData;
  bool _loading = true;
  bool _isConnected = false;

  bool get _isProfessionalRole {
    final role = (_userData?['role'] ?? '').toString().toLowerCase();
    return role.contains('tailor') ||
        role.contains('seamstress') ||
        role.contains('fabric') ||
        role.contains('seller');
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      final data = doc.data();

      final tailorDoc = await FirebaseFirestore.instance
          .collection('tailors')
          .doc(widget.uid)
          .get();
      final tailorData = tailorDoc.data();

      // check if current user is connected to this profile
      final current = FirebaseAuth.instance.currentUser;
      bool connected = false;
      if (current != null) {
        final myConn = await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .collection('connections')
            .doc(widget.uid)
            .get();
        connected = myConn.exists;
      }

      setState(() {
        _userData = data;
        _tailorData = tailorData;
        _isConnected = connected;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed loading user: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    final myConnRef = FirebaseFirestore.instance
        .collection('users')
        .doc(current.uid)
        .collection('connections')
        .doc(widget.uid);

    final theirConnRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('followers')
        .doc(current.uid);

    final myDoc = await myConnRef.get();
    if (myDoc.exists) {
      // already connected -> disconnect
      await myConnRef.delete();
      await theirConnRef.delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'followersCount': FieldValue.increment(-1)});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .update({'followingCount': FieldValue.increment(-1)});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Disconnected')));
        setState(() {
          _isConnected = false;
        });
      }
    } else {
      // connect
      await myConnRef.set({
        'userId': widget.uid,
        'connectedAt': FieldValue.serverTimestamp(),
      });
      await theirConnRef.set({
        'userId': current.uid,
        'connectedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'followersCount': FieldValue.increment(1)});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .update({'followingCount': FieldValue.increment(1)});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connected')));
        setState(() {
          _isConnected = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_userData?['username'] ?? 'Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              (_userData?['profileImage'] ?? '').isNotEmpty
                              ? NetworkImage(_userData!['profileImage'])
                                    as ImageProvider
                              : null,
                          child: (_userData?['profileImage'] ?? '').isEmpty
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData?['username'] ??
                                    _userData?['fullName'] ??
                                    'User',
                                style: AppTextStyles.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              _buildConnectionCounts(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: const Size(80, 36),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            child: Text(
                              _isConnected ? 'Disconnect' : 'Connect',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBusinessInfoSection(),
                    const SizedBox(height: 20),
                    if (_isProfessionalRole ||
                        ((_tailorData?['portfolioImageUrls'] as List?)
                                ?.isNotEmpty ??
                            false)) ...[
                      _buildPortfolioSection(),
                      const SizedBox(height: 20),
                    ],
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Posts', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('userId', isEqualTo: widget.uid)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading posts: ${snap.error}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          );
                        }
                        if (!snap.hasData) {
                          return Text(
                            'No posts yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          );
                        }
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) {
                          return Text(
                            'No posts yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          );
                        }
                        // Sort by createdAt in descending order
                        docs.sort((a, b) {
                          final aTime =
                              (a.data() as Map)['createdAt'] ?? Timestamp.now();
                          final bTime =
                              (b.data() as Map)['createdAt'] ?? Timestamp.now();
                          return (bTime as Timestamp).compareTo(
                            aTime as Timestamp,
                          );
                        });
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                leading:
                                    (data['mediaUrls'] is List &&
                                        (data['mediaUrls'] as List).isNotEmpty)
                                    ? Image.network(
                                        (data['mediaUrls'] as List).first,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(Icons.image);
                                            },
                                      )
                                    : const Icon(Icons.image),
                                title: Text(data['content'] ?? ''),
                                subtitle: Text(
                                  data['createdAt'] != null
                                      ? (data['createdAt'] as Timestamp)
                                            .toDate()
                                            .toString()
                                      : 'No date',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionCounts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('followers')
          .snapshots(),
      builder: (context, followersSnap) {
        final followers = followersSnap.data?.size ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('connections')
              .snapshots(),
          builder: (context, followingSnap) {
            final following = followingSnap.data?.size ?? 0;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    followers.toString(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Followers'),
                  const SizedBox(width: 12),
                  Text(
                    following.toString(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Following'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusinessInfoSection() {
    final role = (_userData?['role'] ?? '').toString().toLowerCase();
    final isProfessional =
        role.contains('tailor') ||
        role.contains('seamstress') ||
        role.contains('fabric') ||
        role.contains('seller');

    final businessName =
        (_tailorData?['businessName'] ?? _userData?['businessName'] ?? '')
            .toString();
    final businessDescription =
        (_tailorData?['businessDescription'] ??
                _userData?['businessDescription'] ??
                _userData?['description'] ??
                _tailorData?['bio'] ??
                _userData?['bio'] ??
                '')
            .toString();
    final businessAddress =
        (_tailorData?['location'] ?? _userData?['businessAddress'] ?? '')
            .toString();
    final businessPhone =
        (_tailorData?['phoneNumber'] ?? _userData?['businessPhone'] ?? '')
            .toString();
    final businessEmail =
        (_tailorData?['email'] ?? _userData?['businessEmail'] ?? '').toString();

    final hasInfo =
        businessName.isNotEmpty ||
        businessDescription.isNotEmpty ||
        businessAddress.isNotEmpty ||
        businessPhone.isNotEmpty ||
        businessEmail.isNotEmpty;

    if (!isProfessional && !hasInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Information', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          if (businessName.isNotEmpty)
            Text(
              businessName,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (businessDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(businessDescription, style: AppTextStyles.bodyMedium),
          ],
          if (businessAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Location: $businessAddress', style: AppTextStyles.bodySmall),
          ],
          if (businessPhone.isNotEmpty)
            Text('Phone: $businessPhone', style: AppTextStyles.bodySmall),
          if (businessEmail.isNotEmpty)
            Text('Email: $businessEmail', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection() {
    final fallbackImages =
        (_tailorData?['portfolioImageUrls'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((url) => url.isNotEmpty)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tailor_portfolio')
              .where('tailorId', isEqualTo: widget.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
              final aTimestamp = aTime is Timestamp
                  ? aTime
                  : Timestamp.fromMillisecondsSinceEpoch(0);
              final bTimestamp = bTime is Timestamp
                  ? bTime
                  : Timestamp.fromMillisecondsSinceEpoch(0);
              return bTimestamp.compareTo(aTimestamp);
            });

            final collectionItems = docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .where((item) => (item['imageUrl'] ?? '').toString().isNotEmpty)
                .toList();

            final hasCollectionItems = collectionItems.isNotEmpty;
            final hasFallbackItems = fallbackImages.isNotEmpty;
            if (!hasCollectionItems && !hasFallbackItems) {
              return Text(
                'No portfolio items yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCollectionItems)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: collectionItems.length,
                    itemBuilder: (context, index) {
                      final item = collectionItems[index];
                      final imageUrl = (item['imageUrl'] ?? '').toString();
                      final description = (item['description'] ?? '')
                          .toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                description.isEmpty
                                    ? 'No description'
                                    : description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (hasFallbackItems && !hasCollectionItems)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: fallbackImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fallbackImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
