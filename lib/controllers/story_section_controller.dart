import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/story_controller.dart';
import '../../models/story_model.dart';

class StoriesSectionController extends GetxController {
  final StoryController storyController;

  var stories = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  final box = GetStorage();
  final viewedStories = <String>{}.obs;

  StoriesSectionController()
      : storyController = Get.put(StoryController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    viewedStories.addAll(box.read<List>('viewedStories')?.cast<String>() ?? []);
    loadStories();
  }

  Future<void> loadStories() async {
    isLoading.value = true;
    try {
      final currentUserInfo = await storyController.fetchCurrentUserInfo();
      final currentUser = storyController.currentUser?.uid;
      final users = await storyController.fetchAllUsers();

      final addStoryItem = {
        'avatar': currentUserInfo['avatar'],
        'username': currentUserInfo['username'],
        'userId': currentUser,
        'isCurrentUser': true,
        'isAddButton': true,
      };

      final List<Map<String, dynamic>> allStoryItems = [];

      final currentUserStories = currentUser != null
          ? await storyController.getStoriesForUser(currentUser)
          : [];
      if (currentUserStories.isNotEmpty) {
        allStoryItems.add({
          'avatar': currentUserInfo['avatar'],
          'username': currentUserInfo['username'],
          'userId': currentUser,
          'isCurrentUser': false,
          'hasActiveStory': true,
          'stories': currentUserStories,
        });
      }

      final others = users.where((u) => u.uid != currentUser).toList();
      final othersStoryItems = await StoryModelSnapshot.fetchStoriesForAllUsers(others);

      allStoryItems.addAll(othersStoryItems);

      final unviewed = allStoryItems.where((s) => !viewedStories.contains(s['userId'])).toList();
      final viewed = allStoryItems.where((s) => viewedStories.contains(s['userId'])).toList();

      final displayList = [
        addStoryItem,
        ...unviewed,
        ...viewed,
      ];

      stories.assignAll(displayList);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    isLoading.value = false;
  }

  void markStoryAsViewed(String userId) {
    if (!viewedStories.contains(userId)) {
      viewedStories.add(userId);
      box.write('viewedStories', viewedStories.toList());
      loadStories();
    }
  }

  void resetViewed(String userId) {
    viewedStories.remove(userId);
    box.write('viewedStories', viewedStories.toList());
    loadStories();
  }
}