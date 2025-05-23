import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

import '../../controllers/final_post_controller.dart';
import '../../widgets/final_post/post_content.dart';
import '../../widgets/final_post/suggestion_overlay.dart';

class FinalPostScreen extends StatelessWidget {
  final List<Uint8List?> mediaList;

  const FinalPostScreen({super.key, required this.mediaList});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinalPostController(mediaList: mediaList));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Bài viết mới',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PostContent(
                  mediaList: mediaList,
                  controller: controller,
                ),
                SuggestionOverlay(controller: controller),
                Obx(() => controller.isLoading.value
                    ? Container(
                  color: Colors.black.withAlpha((0.7 * 255).toInt()),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang đăng bài...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => controller.publishPost(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Obx(() => controller.isLoading.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Chia sẻ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}