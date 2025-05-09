import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'firebase_service.dart';

class PostService {
  final FirebaseService _firebaseService;
  final Uuid _uuid = const Uuid();

  PostService(this._firebaseService);

  Future<String> _uploadMedia(Uint8List media, String userId) async {
    final String fileName = '${_uuid.v4()}.jpg';
    final String filePath = 'posts/$userId/$fileName';

    final ref = _firebaseService.storage.ref().child(filePath);
    final uploadTask = ref.putData(
      media,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    try {
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading media: $e');
      rethrow;
    }
  }

  Future<List<String>> uploadMediaFiles(List<Uint8List?> mediaList, String userId) async {
    List<String> mediaUrls = [];

    for (var media in mediaList) {
      if (media != null) {
        final url = await _uploadMedia(media, userId);
        mediaUrls.add(url);
      }
    }

    return mediaUrls;
  }

  List<String> extractHashtags(String caption) {
    final RegExp hashtagRegExp = RegExp(r'#(\w+)');
    return hashtagRegExp
        .allMatches(caption)
        .map((match) => '#${match.group(1)!}')
        .toList();
  }

  Future<String> createPost({
    required String userId,
    required String caption,
    required List<String> mediaUrls,
    List<String>? hashtags,
  }) async {
    try {
      final List<String> postHashtags = hashtags ?? extractHashtags(caption);
      final postRef = _firebaseService.firestore.collection('posts').doc();

      final postData = {
        'ownerId': userId,
        'caption': caption,
        'hashtags': postHashtags,
        'mediaUrls': mediaUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
        'commentCount': 0,
      };

      await postRef.set(postData);
      await _updateHashtagCounts(postHashtags);

      return postRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> _updateHashtagCounts(List<String> hashtags) async {
    final batch = _firebaseService.firestore.batch();

    for (var tag in hashtags) {
      final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
      final tagRef = _firebaseService.firestore.collection('hashtags').doc(cleanTag);

      final snapshot = await tagRef.get();
      if (snapshot.exists) {
        batch.update(tagRef, {
          'count': FieldValue.increment(1),
        });
      } else {
        batch.set(tagRef, {
          'count': 1,
        });
      }
    }

    await batch.commit();
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final commentId = _uuid.v4();
      final postRef = _firebaseService.firestore.collection('posts').doc(postId);

      await postRef
          .collection('comments')
          .doc(commentId)
          .set({
        'commentId': commentId,
        'uid': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await postRef.update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _firebaseService.firestore.collection('posts').doc(postId);
      final snapshot = await postRef.get();

      if (!snapshot.exists) throw Exception('Post not found');

      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await postRef.update({
        'likes': likes,
        'likeCount': likes.length,
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPopularHashtags({int limit = 10}) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('hashtags')
          .orderBy('count', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'tag': doc.id,
        'count': doc['count'],
      }).toList();
    } catch (e) {
      debugPrint('Error getting popular hashtags: $e');
      return [];
    }
  }
}
