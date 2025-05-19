import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/post_model.dart';
import '../../widgets/post_item.dart';
import '../../controllers/home_controller.dart';

class PostProfileScreen extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const PostProfileScreen({
    Key? key,
    required this.posts,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PostProfileScreen> createState() => _PostProfileScreenState();
}

class _PostProfileScreenState extends State<PostProfileScreen> {
  late ScrollController _scrollController;
  late HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();

    _scrollController = ScrollController();

    // Sau khi frame build xong, scroll đến vị trí bài viết ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double position = widget.initialIndex * 400.0; // 400 là approx height của 1 bài, bạn chỉnh cho phù hợp
      _scrollController.jumpTo(position);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bài viết'),
      ),
      body: ListView.builder(
        controller: _scrollController,
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
