import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

import '../../controllers/final_post_controller.dart';

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
                ListView(
                  children: [
                    if (mediaList.isNotEmpty)
                      Container(
                        height: 300,
                        width: double.infinity,
                        color: Colors.black,
                        child: PageView.builder(
                          itemCount: mediaList.length,
                          itemBuilder: (context, index) {
                            return mediaList[index] != null
                                ? Image.memory(
                              mediaList[index]!,
                              fit: BoxFit.contain,
                            )
                                : const Center(
                              child: Text(
                                'Lỗi hiển thị ảnh',
                                style: TextStyle(color: Colors.white),
                              ),
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
                                        tag,
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
                          'Đang đăng bài...',
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
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}