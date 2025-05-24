import 'package:cloud_firestore/cloud_firestore.dart';

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

  static Future<List<StoryModel>> fetchStoriesForUser(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => StoryModel.fromFirestore(doc, null))
        .where((story) => DateTime.now().difference(story.createdAt).inHours < 24)
        .toList();
  }

  static Future<StoryModel?> fetchLatestStoryForUser(String userId) async {
    final stories = await fetchStoriesForUser(userId);
    return stories.isNotEmpty ? stories.first : null;
  }

  static Future<bool> hasActiveStory(String userId) async {
    final story = await fetchLatestStoryForUser(userId);
    return story != null;
  }
}