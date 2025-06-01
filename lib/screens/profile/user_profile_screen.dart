import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/messages_controller.dart';
import '../../models/user_chat_model.dart';
import '../../models/user_model.dart';
import '../messages/chat_screen.dart';
import 'post_profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  Future<ProfileResult?> _loadUserProfile() async {
    try {
      return await UserModelSnapshot.getUserProfileAndPosts(userId);
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng khác: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileResult?>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('Không tìm thấy người dùng', style: TextStyle(color: Colors.white))),
          );
        }

        final user = snapshot.data!.user;
        final userPosts = snapshot.data!.posts;
        final postCount = snapshot.data!.postCount;
        final createdAt = user.createdAt;
        final joinDate = '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(user.username),
            backgroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Avatar + số liệu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : const AssetImage('assets/avatar.png') as ImageProvider,
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

                const SizedBox(height: 16),
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
                          onPressed: () {
                            if (!Get.isRegistered<MessagesController>()) {
                              Get.put(MessagesController());
                            }
                            final userChat = UserChatModel(
                              uid: userId,
                              fullname: user.fullname,
                              username: user.username,
                              avatarUrl: user.avatarUrl,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(user: userChat),
                              ),
                            );
                          },
                          child: const Text(
                            'Nhắn tin',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Danh sách bài viết
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
                              builder: (_) => PostProfileScreen(
                                posts: userPosts,
                                initialIndex: index,
                              ),
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
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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