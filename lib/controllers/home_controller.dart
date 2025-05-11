import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../models/post_model.dart';
import '../../services/firebase_service.dart';
import '../../services/post_service.dart';

class HomeController extends GetxController {
  final FirebaseService firebaseService = FirebaseService();
  late final PostService postService;

  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasMorePosts = true.obs;
  final Rx<Map<String, bool>> showHeartMap = Rx<Map<String, bool>>({});

  final Rx<Map<String, bool>> likedPostsMap = Rx<Map<String, bool>>({});

  String? currentUserId;

  @override
  void onInit() {
    super.onInit();
    postService = PostService(firebaseService);
    currentUserId = firebaseService.auth.currentUser?.uid;
    loadPosts();
  }

  Future<void> loadPosts() async {
    isLoading.value = true;

    try {
      final newPosts = await postService.getFeedPosts(limit: 10);
      posts.clear();
      posts.addAll(newPosts);
      hasMorePosts.value = newPosts.length == 10;

      if (currentUserId != null) {
        for (var post in newPosts) {
          _checkAndUpdateLikeStatus(post.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (!hasMorePosts.value || isLoading.value) return;

    isLoading.value = true;

    try {
      final lastPost = posts.isNotEmpty ? posts.last : null;
      if (lastPost == null) {
        isLoading.value = false;
        return;
      }

      final lastDocSnapshot = await firebaseService.firestore
          .collection('posts')
          .doc(lastPost.id)
          .get();

      final newPosts = await postService.getFeedPosts(
        limit: 10,
        lastDocument: lastDocSnapshot,
      );

      posts.addAll(newPosts);
      hasMorePosts.value = newPosts.length == 10;

      if (currentUserId != null) {
        for (var post in newPosts) {
          _checkAndUpdateLikeStatus(post.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _checkAndUpdateLikeStatus(String postId) async {
    if (currentUserId == null) return;

    try {
      final isLiked = await postService.hasUserLikedPost(
        postId: postId,
        userId: currentUserId!,
      );

      final currentMap = Map<String, bool>.from(likedPostsMap.value);
      currentMap[postId] = isLiked;
      likedPostsMap.value = currentMap;

      postService.likeStatusStream(
        postId: postId,
        userId: currentUserId!,
      ).listen((isLiked) {
        final updatedMap = Map<String, bool>.from(likedPostsMap.value);
        updatedMap[postId] = isLiked;
        likedPostsMap.value = updatedMap;
      });
    } catch (e) {
      debugPrint('Error checking like status: $e');
    }
  }

  bool isPostLiked(PostModel post) {
    return likedPostsMap.value[post.id] ?? false;
  }

  Future<void> handleLikeToggle(PostModel post) async {
    if (currentUserId == null) return;

    try {
      final currentLiked = likedPostsMap.value[post.id] ?? false;

      await postService.toggleLike(
        postId: post.id,
        userId: currentUserId!,
      );

      final index = posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final newLikeCount = currentLiked
            ? post.likeCount - 1
            : post.likeCount + 1;

        final updatedPost = posts[index].copyWith(
          likeCount: newLikeCount,
        );

        posts[index] = updatedPost;
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thích bài viết: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void showHeartAnimation(String postId) {
    if (currentUserId == null) return;

    final currentMap = Map<String, bool>.from(showHeartMap.value);
    currentMap[postId] = true;
    showHeartMap.value = currentMap;

    final post = posts.firstWhere((p) => p.id == postId);
    if (!isPostLiked(post)) {
      handleLikeToggle(post);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      final updatedMap = Map<String, bool>.from(showHeartMap.value);
      updatedMap[postId] = false;
      showHeartMap.value = updatedMap;
    });
  }

  void navigateToComments(String postId) {
    debugPrint('Navigate to comments for post: $postId');
  }

  void navigateToProfile(String userId) {
    // Implement navigation with GetX
    // Get.to(() => ProfileScreen(userId: userId));
    debugPrint('Navigate to profile for user: $userId');
  }
}