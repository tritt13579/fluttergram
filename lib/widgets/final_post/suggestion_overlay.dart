
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/final_post_controller.dart';

class SuggestionOverlay extends StatelessWidget {
  final FinalPostController controller;

  const SuggestionOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.showHashtagSuggestions.isTrue ||
          controller.showUserSuggestions.isTrue) {
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
                          controller.showHashtagSuggestions.isTrue
                              ? '#$item'
                              : item,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          controller.insertSuggestion(
                            item,
                            isHashtag: controller.showHashtagSuggestions.isTrue,
                          );
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
    });
  }
}