import 'dart:io';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../models/story_model.dart';

class StoryController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> uploadAndSaveStory(File image) async {
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
  }
}
