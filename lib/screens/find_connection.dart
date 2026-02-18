import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// =====================================================
// FIND CONNECTION PAGE
// =====================================================

class FindConnectionPage extends StatefulWidget {
  const FindConnectionPage({super.key});

  @override
  State<FindConnectionPage> createState() => _FindConnectionPageState();
}

class _FindConnectionPageState extends State<FindConnectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Connections")),
      body: Column(
        children: [
          // ================= SEARCH FIELD =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search by username...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // ================= USERS LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  if (doc.id == currentUser?.uid) {
                    return false; // Don't show yourself
                  }

                  final username = (doc['username'] ?? '')
                      .toString()
                      .toLowerCase();

                  return username.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final username = user['username'] ?? "No Name";

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(username),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(
                              userId: user.id,
                              userName: username,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// USER PROFILE PAGE (INSTAGRAM STYLE FOLLOW SYSTEM)
// =====================================================

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // ================= FOLLOW =================

  Future<void> followUser() async {
    if (currentUser == null) return;
    if (currentUser!.uid == widget.userId) return;

    final connectionRef = firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('connections')
        .doc(widget.userId);

    final followerRef = firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUser!.uid);

    final alreadyFollowing = await connectionRef.get();
    if (alreadyFollowing.exists) return;

    final batch = firestore.batch();

    batch.set(connectionRef, {
      'userId': widget.userId,
      'userName': widget.userName,
      'connectedAt': FieldValue.serverTimestamp(),
    });

    batch.set(followerRef, {
      'userId': currentUser!.uid,
      'userName': currentUser!.displayName ?? '',
      'connectedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ================= UNFOLLOW =================

  Future<void> unfollowUser() async {
    if (currentUser == null) return;

    final batch = firestore.batch();

    batch.delete(
      firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('connections')
          .doc(widget.userId),
    );

    batch.delete(
      firestore
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUser!.uid),
    );

    await batch.commit();
  }

  // ================= STREAMS =================

  Stream<bool> isFollowing() {
    if (currentUser == null) return const Stream.empty();

    return firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('connections')
        .doc(widget.userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isFollowedBack() {
    if (currentUser == null) return const Stream.empty();

    return firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('followers')
        .doc(widget.userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> followersCount() {
    return firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> followingCount() {
    return firestore
        .collection('users')
        .doc(widget.userId)
        .collection('connections')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final isMe = currentUser?.uid == widget.userId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamBuilder<int>(
                  stream: followersCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Column(
                      children: [
                        Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Followers"),
                      ],
                    );
                  },
                ),

                StreamBuilder<int>(
                  stream: followingCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Column(
                      children: [
                        Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Following"),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (!isMe)
              StreamBuilder<bool>(
                stream: isFollowing(),
                builder: (context, followSnapshot) {
                  final following = followSnapshot.data ?? false;

                  return StreamBuilder<bool>(
                    stream: isFollowedBack(),
                    builder: (context, backSnapshot) {
                      final followedBack = backSnapshot.data ?? false;

                      String buttonText;
                      Color buttonColor;

                      if (following && followedBack) {
                        buttonText = "Friends";
                        buttonColor = Colors.grey;
                      } else if (following) {
                        buttonText = "Following";
                        buttonColor = Colors.grey;
                      } else if (followedBack) {
                        buttonText = "Follow Back";
                        buttonColor = Colors.blue;
                      } else {
                        buttonText = "Follow";
                        buttonColor = Colors.blue;
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                          ),
                          onPressed: () {
                            if (following) {
                              unfollowUser();
                            } else {
                              followUser();
                            }
                          },
                          child: Text(buttonText),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
