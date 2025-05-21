import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../controllers/messages_controller.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/post_service.dart';
import '../messages/chat_screen.dart';
import 'edit_profile_screen.dart';
import 'post_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostService _postService = PostService(FirebaseService());

  List<PostModel> userPosts = [];
  String username = '';
  String fullname = '';
  String bio = '';
  String avatarUrl = '';
  bool isLoading = true;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String joinDate = '';

  Future<void> _loadUserProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      final data = doc.data();

      if (data != null) {
        final posts = await _postService.getUserPosts(widget.userId);

        final Timestamp? createdAtTimestamp = data['created_at'];
        if (createdAtTimestamp != null) {
          final createdAt = createdAtTimestamp.toDate();
          joinDate = '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
        }

        setState(() {
          username = data['username'] ?? '';
          fullname = data['fullname'] ?? '';
          bio = data['bio'] ?? '';
          avatarUrl = data['avatar_url'] ?? '';
          postCount = data['post_count'] ?? posts.length;
          userPosts = posts;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng khác: $e');
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
      appBar: AppBar(
        title: Text(username),
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
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
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
                      fullname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('@' + username, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(color: Colors.white)),
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
                        final user = UserModel(
                          uid: widget.userId,
                          name: fullname,
                          username: username,
                          avatar: avatarUrl,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(user: user),
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
