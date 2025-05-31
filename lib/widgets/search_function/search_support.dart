import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/searchfl_controller.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../widgets/post_item.dart';
import '../../controllers/profile_controller.dart';
import '../../screens/profile/post_profile_screen.dart';

Widget buildUserResults(SearchFlutterController controller) {
  if (controller.searchQuery.value.isEmpty || controller.searchQuery.value.startsWith('#')) {
    return buildGridPlaceholder(controller.trendingPosts);
  }

  return FutureBuilder<List<UserModel>>(
    future: controller.fetchUsers(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
            child: Text('Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white)));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text('Không tìm thấy người dùng',
              style: TextStyle(color: Colors.white)),
        );
      }

      final users = snapshot.data!;
      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: (user.avatarUrl.isNotEmpty)
                ? CircleAvatar(
              backgroundImage: NetworkImage(user.avatarUrl),
            )
                : CircleAvatar(
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(user.username,
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              String userId = user.uid;
              if (!Get.isRegistered<ProfileController>()) {
                Get.put(ProfileController());
              }
              Get.find<ProfileController>().navigateToProfile(userId);
            },
          );
        },
      );
    },
  );
}

Widget buildHashtagSuggestions(SearchFlutterController controller) {
  if (controller.isLoading.value && controller.hashtagSuggestions.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  if (controller.hashtagSuggestions.isEmpty && controller.searchQuery.value.length > 1) {
    return const Center(
        child: Text('Không tìm thấy hashtag nào',
            style: TextStyle(color: Colors.white)));
  }
  if (controller.hashtagSuggestions.isEmpty) {
    return buildGridPlaceholder(controller.trendingPosts);
  }

  return ListView.builder(
    itemCount: controller.hashtagSuggestions.length,
    itemBuilder: (context, index) {
      final tag = controller.hashtagSuggestions[index];
      return ListTile(
        leading: const Icon(Icons.tag, color: Colors.white70),
        title: Text(tag, style: const TextStyle(color: Colors.white)),
        onTap: () {
          controller.onHashtagSubmitted(tag);
        },
      );
    },
  );
}

Widget buildHashtagPosts(SearchFlutterController controller) {
  if (controller.hashtagPostsResults.isEmpty) {
    return const Center(
      child: Text('Không có bài viết với hashtag này',
          style: TextStyle(color: Colors.white)),
    );
  }
  return ListView.builder(
    itemCount: controller.hashtagPostsResults.length,
    itemBuilder: (context, index) {
      final post = controller.hashtagPostsResults[index];
      return PostItem(
        post: post,
        isLiked: false,
        showHeart: false,
        onDoubleTap: () {},
        onLikeToggle: () {},
        onCommentTap: () {},
        onProfileTap: () {},
      );
    },
  );
}

Widget buildGridPlaceholder(List<PostModel> posts) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length > 20 ? 20 : posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
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
                    posts: [post],
                    initialIndex: 0
                ),
              ),
            );
          },
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
            },
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    ),
  );
}