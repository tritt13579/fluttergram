import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/story_controller.dart';
import 'story_circle.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  final StoryController _storyController = Get.put(StoryController());
  List<Map<String, dynamic>> stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final currentUserInfo = await _storyController.fetchCurrentUserInfo();
      final hasStory = await _storyController.hasActiveStory();
      currentUserInfo['hasActiveStory'] = hasStory;

      final usersSnapshot = await _storyController.fetchAllUsers();
      final otherStories = await Future.wait(usersSnapshot.docs.map((doc) async {
        final userId = doc.id;
        final hasStory = await _storyController.hasStoryForUser(userId);
        return {
          'avatar': doc['avatar_url'] ?? '',
          'username': doc['username'] ?? '',
          'isCurrentUser': false,
          'hasActiveStory': hasStory,
        };
      }).toList());

      setState(() {
        stories = [currentUserInfo, ...otherStories];
      });
    } catch (e) {
      debugPrint('Lỗi khi tải stories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
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
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryCircle(
              avatarUrl: story['avatar'],
              username: story['username'],
              isCurrentUser: story['isCurrentUser'],
              hasActiveStory: story['hasActiveStory'] ?? false,
              onRefresh: _loadStories,
            );
          },
        ),
      ),
    );
  }
}