import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/story_section_controller.dart';
import '../../models/story_model.dart';
import 'story_circle.dart';

class StoriesSection extends StatelessWidget {
  StoriesSection({super.key});

  final StoriesSectionController controller = Get.put(StoriesSectionController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: controller.stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = controller.stories[index];
              final isViewed = controller.viewedStories.contains(item['userId']);
              final stories = item['stories'] as List<StoryModel>?;

              return StoryCircle(
                stories: stories,
                isCurrentUser: item['isCurrentUser'] ?? false,
                isAddButton: item['isAddButton'] ?? false,
                hasActiveStory: item['hasActiveStory'] ?? false,
                isViewed: isViewed,
                onRefresh: controller.loadStories,
                onViewed: () {
                  if (item['hasActiveStory'] == true) {
                    controller.markStoryAsViewed(item['userId']);
                  }
                },
                onAddStory: () {
                  controller.resetViewed(item['userId']);
                },
                avatar: item['avatar'] ?? '',
                username: item['username'] ?? '',
              );
            },
          ),
        ),
      );
    });
  }
}