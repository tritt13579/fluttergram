import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import 'edit_profile_screen.dart';
import 'post_profile_screen.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final controllerAuth = Get.put(ControllerAuth());

  List<PostModel> userPosts = [];

  String username = '';
  String fullname = '';
  String bio = '';
  String avatarUrl = '';
  String joinDate = '';
  bool isLoading = true;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final profileResult = await UserModelSnapshot.getUserProfileAndPosts(uid);

      final user = profileResult.user;
      final posts = profileResult.posts;

      final createdAt = user.createdAt;
      joinDate = '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

      setState(() {
        username = user.username;
        fullname = user.fullname;
        bio = user.bio;
        avatarUrl = user.avatarUrl;
        postCount = profileResult.postCount;
        userPosts = posts;
        isLoading = false;
      });
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
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(value: postCount.toString(), label: 'Bài viết'),
                        _StatItem(value: joinDate, label: 'Tham Gia'),
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
                    Text('@$username', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nút chỉnh sửa & đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                            builder: (context) => EditProfileScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadUserProfile();
                        }
                      },
                      child: const Text(
                        'Chỉnh sửa trang cá nhân',
                        style: TextStyle(fontSize: 12.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        controllerAuth.signout();
                      },
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 12.4),
                      ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostProfileScreen(posts: userPosts, initialIndex: index),
                        ),
                      );
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
                    ),
                  );
                },
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