import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../screens/stories/add_stories.dart';
import '../../screens/stories/stories_screen.dart';
import '../../controllers/story_controller.dart';
import '../../utils/app_permissions.dart';

class StoryCircle extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final String? userId;
  final bool isCurrentUser;
  final bool hasActiveStory;
  final VoidCallback? onRefresh;

  const StoryCircle({
    super.key,
    required this.avatarUrl,
    required this.username,
    this.userId,
    required this.isCurrentUser,
    required this.hasActiveStory,
    this.onRefresh,
  });

  Future<void> _onTap() async {
    final controller = Get.find<StoryController>();

    if (isCurrentUser) {
      final hasStory = await controller.hasActiveStory();
      if (hasStory) {
        final story = await controller.getCurrentUserStory();
        if (story != null) {
          Get.to(() => StoriesScreen(
            username: story.username,
            avatarUrl: story.userAvatar,
            imageUrl: story.imageUrl,
            postedDateTime: story.createdAt,
            isCurrentUser: true,
            onDelete: () async {
              await controller.deleteCurrentUserStory();
              Get.back();
              onRefresh?.call();
              Get.snackbar('Đã xoá', 'Story của bạn đã được xoá');
            },
          ));
        }
      } else {
        final hasPermission = await AppPermissions.requestMediaPermissions();
        if (!hasPermission) return;

        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final image = File(picked.path);
          await Get.to(() => AddStoryScreen(
            image: image,
            avatarUrl: avatarUrl,
            username: username,
          ));
          onRefresh?.call();
        }
      }
    } else if (userId != null) {
      final story = await controller.getUserStory(userId!);
      if (story != null) {
        Get.to(() => StoriesScreen(
          username: story.username,
          avatarUrl: story.userAvatar,
          imageUrl: story.imageUrl,
          postedDateTime: story.createdAt,
          isCurrentUser: false,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: hasActiveStory
                    ? BoxDecoration(
                  border: Border.all(
                    color: Colors.red[400]!,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                )
                    : null,
                padding: hasActiveStory ? const EdgeInsets.all(2) : null,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              if (isCurrentUser && !hasActiveStory)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(username, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}