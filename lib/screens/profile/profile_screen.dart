import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'post_profile_screen.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final controllerAuth = Get.put(ControllerAuth());

    return FutureBuilder<ProfileResult?>(
      future: _loadUserProfile(auth.currentUser?.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!.user;
        final userPosts = snapshot.data!.posts;
        final postCount = snapshot.data!.postCount;
        final createdAt = user.createdAt;
        final joinDate = '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

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
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
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
                          user.fullname,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('@${user.username}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(user.bio, style: const TextStyle(color: Colors.white)),
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
                            // Reload lại thông tin sau khi chỉnh sửa
                            if (result == true) {
                              // ignore: use_build_context_synchronously
                              (context as Element).markNeedsBuild();
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
      },
    );
  }

  Future<ProfileResult?> _loadUserProfile(String? uid) async {
    if (uid == null) return null;
    try {
      return await UserModelSnapshot.getUserProfileAndPosts(uid);
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng: $e');
      return null;
    }
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