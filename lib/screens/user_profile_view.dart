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
  bool _loading = true;
  bool _isConnected = false;

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
      final data = doc.data() as Map<String, dynamic>?;
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
          if (_userData != null && _userData!['followersCount'] is int) {
            _userData!['followersCount'] =
                (_userData!['followersCount'] as int) - 1;
          }
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
          if (_userData != null && _userData!['followersCount'] is int) {
            _userData!['followersCount'] =
                (_userData!['followersCount'] as int) + 1;
          }
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
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text(
                                      (_userData?['followersCount'] ?? 0)
                                          .toString(),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('Followers'),
                                    const SizedBox(width: 12),
                                    Text(
                                      (_userData?['followingCount'] ?? 0)
                                          .toString(),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('Following'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _toggleFollow,
                          child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
}
