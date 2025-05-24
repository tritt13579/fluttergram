import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/story_model.dart';
import '../../controllers/story_controller.dart';

class StoriesScreen extends StatelessWidget {
  final List<StoryModel> stories;
  final bool isCurrentUser;

  const StoriesScreen({
    super.key,
    required this.stories,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();
    final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

    final userAvatar = stories.first.userAvatar;
    final username = stories.first.username;

    final storyController = Get.find<StoryController>();

    for (final story in stories) {
      storyController.loadLikeStatus(story.id);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(userAvatar),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (context, idx, _) {
                final currentStory = stories[idx];
                final timeAgoText = timeago.format(currentStory.createdAt, locale: 'vi');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(timeAgoText,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                );
              },
            ),
            const Spacer(),
            const SizedBox(width: 10),
            const Icon(Icons.more_horiz, color: Colors.white),
          ],
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: stories.length,
            onPageChanged: (index) {
              currentIndex.value = index;
            },
            itemBuilder: (context, index) {
              final story = stories[index];
              return Image.network(
                story.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (context, idx, _) {
                final storyId = stories[idx].id;
                return Obx(() => Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        storyController.liked[storyId]?.value == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: storyController.liked[storyId]?.value == true
                            ? Colors.red
                            : Colors.white,
                        size: 30,
                      ),
                      onPressed: () => storyController.toggleLike(storyId),
                    ),
                    Text(
                      (storyController.likes[storyId]?.value ?? 0).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ));
              },
            ),
          ),
          if (stories.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: ValueListenableBuilder<int>(
                valueListenable: currentIndex,
                builder: (context, idx, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(stories.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: idx == index ? 32 : 16,
                      decoration: BoxDecoration(
                        color: idx == index ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}