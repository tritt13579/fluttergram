import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/post_model.dart';
import '../../widgets/post_item.dart';
import '../../controllers/home_controller.dart';

class PostProfileScreen extends StatelessWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const PostProfileScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final ScrollController scrollController = ScrollController();

    // Scroll to initialIndex after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final double position = initialIndex * 400.0;
      if (scrollController.hasClients) {
        scrollController.jumpTo(position);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
      ),
      body: ListView.builder(
        controller: scrollController,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Obx(() {
            final isLiked = controller.likedPostsMap.value[post.id] ?? false;
            final showHeart = controller.showHeartMap.value[post.id] ?? false;

            return PostItem(
              post: post,
              isLiked: isLiked,
              showHeart: showHeart,
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