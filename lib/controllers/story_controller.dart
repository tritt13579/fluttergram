import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../models/story_model.dart';

class StoryController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  User? get currentUser => _firebaseService.currentUser;
  final likes = <String, RxInt>{}.obs;
  final liked = <String, RxBool>{}.obs;
  final isLoading = false.obs;

  Future<void> loadLikeStatus(String storyId) async {
    final likeCount = await StoryModelSnapshot.fetchLikeCount(storyId);
    likes[storyId] = RxInt(likeCount);

    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    final userLiked = await StoryModelSnapshot.hasUserLiked(storyId, userId);
    liked[storyId] = RxBool(userLiked);
  }

  Future<void> toggleLike(String storyId) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    final isLiked = liked[storyId]?.value == true;
    await StoryModelSnapshot.toggleLike(storyId, userId, isLiked: isLiked);

    final likeCount = await StoryModelSnapshot.fetchLikeCount(storyId);
    likes[storyId]?.value = likeCount;
    liked[storyId]?.value = !isLiked;
  }

  Future<Map<String, dynamic>> fetchCurrentUserInfo() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception("Chưa đăng nhập");

    final userMap = await UserModelSnapshot.getMapUserModel();
    final userModel = userMap[user.uid];
    if (userModel == null) throw Exception("Không tìm thấy user");

    return {
      'avatar': userModel.avatarUrl,
      'username': userModel.username,
      'isCurrentUser': true,
    };
  }

  Future<List<StoryModel>> getStoriesForUser(String userId) async {
    return await StoryModelSnapshot.fetchStoriesForUser(userId);
  }

  Future<StoryModel?> getLatestStoryForUser(String userId) async {
    return await StoryModelSnapshot.fetchLatestStoryForUser(userId);
  }

  Future<bool> hasActiveStoryForUser(String userId) async {
    return await StoryModelSnapshot.hasActiveStory(userId);
  }

  Future<void> uploadAndSaveStory(File image) async {
    isLoading.value = true;
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final userMap = await UserModelSnapshot.getMapUserModel();
      final userModel = userMap[user.uid];
      if (userModel == null) return;

      await StoryModelSnapshot.uploadAndCreateStory(
        image: image,
        user: userModel,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserModel>> fetchAllUsers() async {
    return await UserModelSnapshot.fetchAllUsers();
  }
}