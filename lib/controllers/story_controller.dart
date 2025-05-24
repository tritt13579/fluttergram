import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../models/story_model.dart';

class StoryController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  User? get currentUser => _firebaseService.currentUser;
  final likes = <String, RxInt>{}.obs;
  final liked = <String, RxBool>{}.obs;
  final isLoading = false.obs;

  Future<void> loadLikeStatus(String storyId) async {
    final doc = await _firebaseService.firestore.collection('stories').doc(storyId).get();
    likes[storyId] = RxInt(doc.data()?['likeCount'] ?? 0);

    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    final likeDoc = await _firebaseService.firestore
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .doc(userId)
        .get();
    liked[storyId] = RxBool(likeDoc.exists);
  }

  Future<void> toggleLike(String storyId) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    final docRef = _firebaseService.firestore.collection('stories').doc(storyId);
    final likeRef = docRef.collection('likes').doc(userId);

    if (liked[storyId]?.value == true) {
      await likeRef.delete();
      await docRef.update({'likeCount': FieldValue.increment(-1)});
      likes[storyId]?.value = (likes[storyId]?.value ?? 1) - 1;
      liked[storyId]?.value = false;
    } else {
      await likeRef.set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
      await docRef.update({'likeCount': FieldValue.increment(1)});
      likes[storyId]?.value = (likes[storyId]?.value ?? 0) + 1;
      liked[storyId]?.value = true;
    }
  }

  Future<Map<String, dynamic>> fetchCurrentUserInfo() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception("Chưa đăng nhập");

    final doc = await _firebaseService.firestore.collection('users').doc(user.uid).get();

    final data = doc.data()!;
    return {
      'avatar': data['avatar_url'] ?? '',
      'username': data['username'] ?? '',
      'isCurrentUser': true,
    };
  }

  Future<List<StoryModel>> getStoriesForUser(String userId) async {
    return await StoryModel.fetchStoriesForUser(userId);
  }

  Future<StoryModel?> getLatestStoryForUser(String userId) async {
    return await StoryModel.fetchLatestStoryForUser(userId);
  }

  Future<bool> hasActiveStoryForUser(String userId) async {
    return await StoryModel.hasActiveStory(userId);
  }

  Future<void> uploadAndSaveStory(File image) async {
    isLoading.value = true;
    try{
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final userDoc = await _firebaseService.getDocument(
        collection: 'users',
        documentId: user.uid,
      );

      final userData = userDoc.data() as Map<String, dynamic>?;

      final path = 'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await _firebaseService.uploadImage(image: image, path: path);

      final story = StoryModel(
        id: '',
        userId: user.uid,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        username: userData?['username'] ?? '',
        userAvatar: userData?['avatar_url'] ?? '',
      );

      await _firebaseService.createDocument(
        collection: 'stories',
        data: story.toMap(),
      );
    } finally {isLoading.value = false;}

  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllUsers() async {
    return await _firebaseService.firestore.collection('users').get();
  }
}