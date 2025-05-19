import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../models/post_model.dart';
import '../../services/firebase_service.dart';
import '../../services/post_service.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../widgets/comment_bottom_sheet.dart';

class HomeController extends GetxController {
  final FirebaseService firebaseService = FirebaseService();
  late final PostService postService;

  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasMorePosts = true.obs;
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool hasMoreComments = true.obs;
  final TextEditingController commentController = TextEditingController();
  DocumentSnapshot? lastCommentDoc;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<Map<String, bool>> showHeartMap = Rx<Map<String, bool>>({});

  final Rx<Map<String, bool>> likedPostsMap = Rx<Map<String, bool>>({});

  String? currentUserId;

  @override
  void onInit() {
    super.onInit();
    postService = PostService(firebaseService);
    currentUserId = firebaseService.auth.currentUser?.uid;
    loadPosts();
    if (currentUserId != null) {
      loadCurrentUserData();
    }
  }

  Future<void> loadCurrentUserData() async {
    try {
      final userDoc = await firebaseService.firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromMap({
          'uid': currentUserId,
          'fullname': userData['fullname'] ?? 'User',
          'username': userData['username'] ?? 'user',
          'avatar_url': userData['avatar_url'],
        });
      }
    } catch (e) {
      debugPrint('Error loading current user data: $e');
    }
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

  Future<void> loadComments(String postId) async {
    isLoadingComments.value = true;
    comments.clear();
    lastCommentDoc = null;
    hasMoreComments.value = true;

    try {
      final commentsList = await postService.getPostComments(
        postId,
        limit: 20,
      );

      comments.assignAll(commentsList);

      if (commentsList.isNotEmpty) {
        final lastDoc = await firebaseService.firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentsList.last.id)
            .get();

        lastCommentDoc = lastDoc;
      }

      hasMoreComments.value = commentsList.length == 20;
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> loadMoreComments(String postId) async {
    if (!hasMoreComments.value || isLoadingComments.value || lastCommentDoc == null) return;

    isLoadingComments.value = true;

    try {
      final commentsList = await postService.getPostComments(
        postId,
        limit: 20,
        lastDocument: lastCommentDoc,
      );

      comments.addAll(commentsList);

      if (commentsList.isNotEmpty) {
        final lastDoc = await firebaseService.firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentsList.last.id)
            .get();

        lastCommentDoc = lastDoc;
      }

      hasMoreComments.value = commentsList.length == 20;
    } catch (e) {
      debugPrint('Error loading more comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> addComment(String postId) async {
    if (currentUserId == null || commentController.text.trim().isEmpty) return;

    final text = commentController.text.trim();
    commentController.clear();

    try {
      final userDoc = await firebaseService.firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      String? username;
      String? userAvatar;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        username = userData['username'];
        userAvatar = userData['avatar_url'];
      }

      await postService.addComment(
        postId: postId,
        userId: currentUserId!,
        text: text,
        username: username,
        userAvatar: userAvatar,
      );

      loadComments(postId);

      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final updatedPost = posts[index].copyWith(
          commentCount: posts[index].commentCount + 1,
        );

        posts[index] = updatedPost;
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thêm bình luận: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToComments(String postId) {
    loadComments(postId);
    Get.bottomSheet(
      CommentBottomSheet(
        postId: postId,
        controller: this,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.black,
    );
  }

  void navigateToProfile(String userId) {
    // Implement navigation with GetX
    // Get.to(() => ProfileScreen(userId: userId));
    debugPrint('Navigate to profile for user: $userId');
  }
}