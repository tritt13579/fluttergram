import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../screens/stories/add_stories.dart';
import '../../screens/stories/stories_screen.dart';
import '../../controllers/story_controller.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_permissions.dart';

class StoryCircle extends StatelessWidget {
  final List<StoryModel>? stories;
  final bool isCurrentUser;
  final bool isAddButton;
  final bool hasActiveStory;
  final bool isViewed;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewed;
  final VoidCallback? onAddStory;
  final String avatar;
  final String username;

  const StoryCircle({
    super.key,
    this.stories,
    this.isCurrentUser = false,
    this.isAddButton = false,
    this.hasActiveStory = false,
    this.isViewed = false,
    this.onRefresh,
    this.onViewed,
    this.onAddStory,
    required this.avatar,
    required this.username,
  });

  Future<void> _onTap(BuildContext context) async {
    final controller = Get.find<StoryController>();

    if (isAddButton) {
      final hasPermission = await AppPermissions.requestMediaPermissions();
      if (!hasPermission) return;

      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final image = File(picked.path);

        final userInfo = await controller.fetchCurrentUserInfo();
        final user = UserModel(
          uid: controller.currentUser?.uid ?? '',
          name: userInfo['username'] ?? '',
          username: userInfo['username'] ?? '',
          avatar: userInfo['avatar'] ?? '',
        );

        await Get.to(() => AddStoryScreen(
          image: image,
          user: user,
        ));
        onAddStory?.call();
        onRefresh?.call();
      }
    } else if (stories != null && stories!.isNotEmpty) {
      await Get.to(() => StoriesScreen(
        stories: stories!,
        isCurrentUser: isCurrentUser,
      ));
      onViewed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    if (hasActiveStory) {
      borderColor = isViewed ? Colors.grey : Colors.red[400]!;
    }
    return SizedBox(
      width: 72,
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: hasActiveStory || isAddButton
                      ? BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: hasActiveStory ? 2 : 3.5,
                    ),
                    shape: BoxShape.circle,
                  )
                      : null,
                  padding: hasActiveStory ? const EdgeInsets.all(2) : null,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                ),
                if (isAddButton)
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
            Text(
              username,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}