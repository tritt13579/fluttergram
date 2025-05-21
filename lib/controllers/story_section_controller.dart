import 'package:get/get.dart';
import '../../controllers/story_controller.dart';

class StoriesSectionController extends GetxController {
  final StoryController storyController = Get.find<StoryController>();
  var stories = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    isLoading.value = true;
    try {
      final currentUserInfo = await storyController.fetchCurrentUserInfo();
      final hasStory = await storyController.hasActiveStory();
      currentUserInfo['hasActiveStory'] = hasStory;
      final currentUser = storyController.currentUser?.uid;
      final usersSnapshot = await storyController.fetchAllUsers();

      final List<Map<String, dynamic>> filteredStories = [];

      if (hasStory) {
        filteredStories.add({
          ...currentUserInfo,
          'userId': currentUser,
        });
      }

      for (final doc in usersSnapshot.docs) {
        final userId = doc.id;
        if (userId == currentUser) continue;
        final hasStory = await storyController.hasStoryForUser(userId);
        if (hasStory) {
          filteredStories.add({
            'avatar': doc['avatar_url'] ?? '',
            'username': doc['username'] ?? '',
            'userId': userId,
            'isCurrentUser': false,
            'hasActiveStory': true,
          });
        }
      }

      stories.assignAll(filteredStories);
    } catch (e) {
      // handle error if needed
    }
    isLoading.value = false;
  }
}