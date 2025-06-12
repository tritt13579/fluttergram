import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/edit_post_controller.dart';
import '../../models/post_model.dart';

class EditPostScreen extends StatelessWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditPostController(post: post));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Chỉnh sửa bài viết',
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
                ListView(
                  children: [
                    // hiển thị ảnh
                    if (post.mediaUrls.isNotEmpty)
                      Container(
                        height: 300,
                        width: double.infinity,
                        color: Colors.black,
                        child: PageView.builder(
                          itemCount: post.mediaUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Image.network(
                                  post.mediaUrls[index],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(Icons.error, size: 40, color: Colors.grey[400]),
                                  ),
                                ),
                                if (post.mediaUrls.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}/${post.mediaUrls.length}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: controller.captionController,
                        focusNode: controller.captionFocusNode,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Thêm chú thích...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const Divider(color: Colors.grey),

                    //hashtag và người tag
                    Obx(() {
                      List<Widget> chips = [];

                      if (controller.extractedHashtags.isNotEmpty) {
                        chips.add(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 16.0),
                                child: Text(
                                  'Hashtags:',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Wrap(
                                  spacing: 8,
                                  children: controller.extractedHashtags.map((tag) {
                                    return Chip(
                                      backgroundColor: Colors.grey[800],
                                      label: Text(
                                        '#$tag',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (controller.extractedTaggedUsers.isNotEmpty) {
                        chips.add(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 16.0),
                                child: Text(
                                  'Đã gắn thẻ:',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Wrap(
                                  spacing: 8,
                                  children: controller.extractedTaggedUsers.map((user) {
                                    return Chip(
                                      backgroundColor: Colors.grey[800],
                                      label: Text(
                                        "@$user",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: chips,
                      );
                    }),
                  ],
                ),

                // Gợi ý
                Obx(() {
                  if (controller.showHashtagSuggestions.isTrue || controller.showUserSuggestions.isTrue) {
                    final suggestions = controller.showHashtagSuggestions.isTrue
                        ? controller.filteredHashtags
                        : controller.filteredUsers;
                    final title = controller.showHashtagSuggestions.isTrue
                        ? "Hashtags ${controller.searchPrefix}"
                        : "Người dùng ${controller.searchPrefix}";

                    return Positioned(
                      top: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.3 * 255).toInt()),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Flexible(
                              child: ListView.builder(
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final item = suggestions[index];
                                  return ListTile(
                                    dense: true,
                                    leading: controller.showUserSuggestions.isTrue
                                        ? CircleAvatar(
                                      backgroundColor: Colors.grey[800],
                                      child: Text(
                                        item[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    )
                                        : null,
                                    title: Text(
                                      controller.showHashtagSuggestions.isTrue ? '#$item' : item,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      controller.insertSuggestion(item, isHashtag: controller.showHashtagSuggestions.isTrue);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),

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
                          'Đang cập nhật...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink()
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => controller.updatePost(),
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
                'Cập nhật',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}