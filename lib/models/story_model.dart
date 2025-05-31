import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttergram/models/user_model.dart';

import '../services/firebase_service.dart';

class StoryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime createdAt;
  final String username;
  final String userAvatar;

  StoryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    required this.username,
    required this.userAvatar,
  });

  factory StoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      SnapshotOptions? options,
      ) {
    final data = doc.data()!;
    return StoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'userAvatar': userAvatar,
    };
  }
}

class StoryModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();

  static Future<void> uploadAndCreateStory({
    required File image,
    required UserModel user,
  }) async {
    final path = 'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageUrl = await FirebaseService().uploadImage(image: image, path: path);

    final story = StoryModel(
      id: '',
      userId: user.uid,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      username: user.username,
      userAvatar: user.avatarUrl,
    );

    await FirebaseService().createDocument(
      collection: 'stories',
      data: story.toMap(),
    );
  }

  static Future<List<StoryModel>> fetchStoriesForUser(String userId) async {
    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => StoryModel.fromFirestore(doc, null))
        .where((story) => DateTime.now().difference(story.createdAt).inHours < 24)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchStoriesForAllUsers(List<UserModel> users, {String? excludeUserId}) async {
    List<Map<String, dynamic>> result = [];
    for (final user in users) {
      if (excludeUserId != null && user.uid == excludeUserId) continue;
      final stories = await fetchStoriesForUser(user.uid);
      if (stories.isNotEmpty) {
        result.add({
          'avatar': user.avatarUrl,
          'username': user.username,
          'userId': user.uid,
          'isCurrentUser': false,
          'hasActiveStory': true,
          'stories': stories,
        });
      }
    }
    return result;
  }

  static Future<StoryModel?> fetchLatestStoryForUser(String userId) async {
    final stories = await fetchStoriesForUser(userId);
    return stories.isNotEmpty ? stories.first : null;
  }

  static Future<bool> hasActiveStory(String userId) async {
    final story = await fetchLatestStoryForUser(userId);
    return story != null;
  }

  static Future<int> fetchLikeCount(String storyId) async {
    final doc = await _firebaseService.firestore.collection('stories').doc(storyId).get();
    return doc.data()?['likeCount'] ?? 0;
  }

  static Future<bool> hasUserLiked(String storyId, String userId) async {
    final likeDoc = await _firebaseService.firestore
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .doc(userId)
        .get();
    return likeDoc.exists;
  }

  static Future<void> toggleLike(String storyId, String userId, {required bool isLiked}) async {
    final docRef = _firebaseService.firestore.collection('stories').doc(storyId);
    final likeRef = docRef.collection('likes').doc(userId);

    if (isLiked) {
      await likeRef.delete();
      await docRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
      await docRef.update({'likeCount': FieldValue.increment(1)});
    }
  }
}