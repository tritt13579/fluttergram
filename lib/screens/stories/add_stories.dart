import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/story_controller.dart';
import '../../models/user_chat_model.dart';
import '../../utils/snackbar_utils.dart';

class AddStoryScreen extends StatelessWidget {
  final File image;
  final UserChatModel user;

  AddStoryScreen({
    super.key,
    required this.image,
    required this.user,
  });

  final StoryController controller = Get.find<StoryController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => AbsorbPointer(
      absorbing: controller.isLoading.value,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: BackButton(),
              title: const Text('Story'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                      await controller.uploadAndSaveStory(
                        image,
                      );
                      Get.back();
                      SnackbarUtils.showSuccess('Đã đăng Story!');
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[900]?.withAlpha((0.85 * 255).toInt()),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(user.avatarUrl),
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Tin của bạn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[900]?.withAlpha((0.85 * 255).toInt()),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          if (controller.isLoading.value)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    ));
  }
}