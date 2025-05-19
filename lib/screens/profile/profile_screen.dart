import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../controllers/auth_controller.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostService _postService = PostService(FirebaseService());

  List<PostModel> userPosts = [];

  String username = '';
  String fullname = '';
  String bio = '';
  String avatarUrl = '';
  bool isLoading = true;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      if (data != null) {
        final posts = await _postService.getUserPosts(uid);

        setState(() {
          username = data['username'] ?? '';
          fullname = data['fullname'] ?? '';
          bio = data['bio'] ?? '';
          avatarUrl = data['avatar_url'] ?? '';
          postCount = data['post_count'] ?? posts.length;
          followerCount = data['follower_count'] ?? 0;
          followingCount = data['following_count'] ?? 0;
          userPosts = posts;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin người dùng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : const AssetImage('assets/avatar.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(value: postCount.toString(), label: 'Bài viết'),
                        _StatItem(value: followerCount.toString(), label: 'Người theo dõi'),
                        _StatItem(value: followingCount.toString(), label: 'Đang theo dõi'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Họ tên, username, bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(username, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút chỉnh sửa & đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadUserProfile();
                        }
                      },
                      child: const Text('Chỉnh sửa trang cá nhân'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        AuthService().signout(context: context);
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Danh sách bài viết dạng lưới
            Padding(
              padding: const EdgeInsets.all(2),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userPosts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                  itemBuilder: (context, index) {
                    final post = userPosts[index];
                    final imageUrl = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null;

                    if (imageUrl == null) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.white),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        // TODO: Mở màn hình chi tiết bài viết
                      },
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, color: Colors.white),
                          );
                        },
                      ),
                    );
                  }

              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
