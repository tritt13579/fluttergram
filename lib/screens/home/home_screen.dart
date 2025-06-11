import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../widgets/post_item.dart';
import '../../widgets/story/stories_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshHomeData,
        child: Obx(() {
          if (controller.posts.isEmpty && !controller.isLoading.value) {
            return _buildEmptyView(controller);
          }
          return _buildPostsList(controller);
        }),
      ),
    );
  }

  Widget _buildEmptyView(HomeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_album, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài viết nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.loadPosts,
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(HomeController controller) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
            controller.loadMorePosts();
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: controller.posts.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoriesSection();
          }

          if (index == controller.posts.length + 1) {
            return Obx(() => controller.hasMorePosts.value
                ? Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
                : const SizedBox());
          }

          final postIndex = index - 1;
          final post = controller.posts[postIndex];

          return Obx(() {
            final isLiked = controller.likedPostsMap.value[post.id] ?? false;

            return PostItem(
              post: post,
              isLiked: isLiked,
              showHeart: controller.showHeartMap.value[post.id] ?? false,
              onDoubleTap: () => controller.showHeartAnimation(post.id),
              onLikeToggle: () => controller.handleLikeToggle(post),
              onCommentTap: () => controller.navigateToComments(post.id),
              onProfileTap: () => controller.navigateToProfile(post.ownerId),
            );
          });
        },
      ),
    );
  }
}