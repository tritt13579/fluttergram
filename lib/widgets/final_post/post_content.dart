
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../controllers/final_post_controller.dart';

class PostContent extends StatelessWidget {
  final List<Uint8List?> mediaList;
  final FinalPostController controller;

  const PostContent({
    super.key,
    required this.mediaList,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
    );
  }
}
