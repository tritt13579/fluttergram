import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../models/story_model.dart';

class StoryController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  User? get currentUser => _firebaseService.currentUser;

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

  Future<StoryModel?> getUserStory(String userId) async {
    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first;
    final story = StoryModel.fromFirestore(data, null);
    final isValid = DateTime.now().difference(story.createdAt).inHours < 24;
    return isValid ? story : null;
  }

  Future<void> deleteCurrentUserStory() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  Future<bool> hasActiveStory() async {
    final user = _firebaseService.currentUser;
    if (user == null) return false;

    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final story = snapshot.docs.first.data();
    final createdAt = (story['createdAt'] as Timestamp).toDate();
    return DateTime.now().difference(createdAt).inHours < 24;
  }

  Future<StoryModel?> getCurrentUserStory() async {
    final user = _firebaseService.currentUser;
    if (user == null) return null;

    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first;
    final story = StoryModel.fromFirestore(data, null);
    final isValid = DateTime.now().difference(story.createdAt).inHours < 24;
    return isValid ? story : null;
  }

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
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllUsers() async {
    return await _firebaseService.firestore.collection('users').get();
  }

  Future<bool> hasStoryForUser(String userId) async {
    final snapshot = await _firebaseService.firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final story = snapshot.docs.first.data();
    final createdAt = (story['createdAt'] as Timestamp).toDate();
    return DateTime.now().difference(createdAt).inHours < 24;
  }
}
