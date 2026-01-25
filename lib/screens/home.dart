import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ensure these filenames match your project files exactly
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

  // The 4 main movements of your app
  final List<Widget> _pages = [
    const HomeFeedPage(),
    const ExplorePage(),
    const CustomerDashboard(),
    const CustomerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // App Bar only shows on the Home Feed (Index 0)
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: const Text(
                "FASHION HUB",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () {},
                ),
              ],
            )
          : null,

      // IndexedStack keeps the scroll position alive when switching tabs
      body: IndexedStack(index: _currentIndex, children: _pages),

      // FAB only on Home Feed
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFF06262),
              elevation: 4,
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF06262),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Feed"),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// --- THE HOME FEED MOVEMENT ---
class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  // THE LIKE LOGIC: Adds/Removes user ID from the 'likes' array in Firestore
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 5),
            child: Text(
              "Top Tailors",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildStories(),
          const SizedBox(height: 15),
          _buildCategories(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Latest Inspiration",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          _buildGlobalFeed(),
        ],
      ),
    );
  }

  Widget _buildStories() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 15),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF06262), width: 2),
          ),
          child: const CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150?u=fashion',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final cats = ["All", "Tradition", "Bridal", "Suits", "Lace"];
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: index == 0 ? Colors.black : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            cats[index],
            style: TextStyle(
              color: index == 0 ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
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
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var post = doc.data() as Map<String, dynamic>;
            List likes = post['likes'] ?? [];
            bool isLiked = likes.contains(currentUserId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.grey),
                  title: Text(
                    post['authorName'] ?? "Designer",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post['authorRole'] ?? "Fashion Hub"),
                ),
                Image.network(
                  post['imageUrl'] ?? '',
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // ACTION BAR
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black,
                        ),
                        onPressed: () => _toggleLike(doc.id, likes),
                      ),
                      Text(
                        "${likes.length}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 15),
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 15),
                      const Icon(Icons.send_outlined),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "${post['authorName']} ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post['description'] ?? ""),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
              ],
            );
          },
        );
      },
    );
  }
}
