import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import 'firebase_service.dart';

class PostService {
  final FirebaseService firebaseService;
  final Uuid _uuid = const Uuid();

  PostService(this.firebaseService);

  Future<String> _uploadMedia(Uint8List media, String userId) async {
    final String fileName = '${_uuid.v4()}.jpg';
    final String filePath = 'posts/$userId/$fileName';

    final ref = firebaseService.storage.ref().child(filePath);
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
    String? ownerUsername,
    String? ownerPhotoUrl,
    List<String>? hashtags,
  }) async {
    try {
      final List<String> postHashtags = hashtags ?? extractHashtags(caption);
      final postRef = firebaseService.firestore.collection('posts').doc();

      final postModel = PostModel(
        id: postRef.id,
        ownerId: userId,
        ownerUsername: ownerUsername,
        ownerPhotoUrl: ownerPhotoUrl,
        caption: caption,
        mediaUrls: mediaUrls,
        hashtags: postHashtags,
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
      );

      await postRef.set(postModel.toMap());
      await _updateHashtagCounts(postHashtags);

      return postRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> _updateHashtagCounts(List<String> hashtags) async {
    final batch = firebaseService.firestore.batch();

    for (var tag in hashtags) {
      final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
      final tagRef = firebaseService.firestore.collection('hashtags').doc(cleanTag);

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

  Future<List<PostModel>> getTrendingPosts({int limit = 20}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<void> updatePost({
    required String postId,
    required String caption,
    required List<String> hashtags,
  }) async {
    try {
      final postDoc = await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) throw Exception('Bài viết không tồn tại');

      final currentPost = PostModel.fromFirestore(postDoc);
      final oldHashtags = currentPost.hashtags;

      await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .update({
        'caption': caption,
        'hashtags': hashtags,
      });

      await _updateHashtagCountsForEdit(oldHashtags, hashtags);
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> _updateHashtagCountsForEdit(
      List<String> oldHashtags,
      List<String> newHashtags
      ) async {
    final batch = firebaseService.firestore.batch();

    for (var tag in oldHashtags) {
      if (!newHashtags.contains(tag)) {
        final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        final tagRef = firebaseService.firestore.collection('hashtags').doc(cleanTag);

        final snapshot = await tagRef.get();
        if (snapshot.exists) {
          final currentCount = snapshot.data()?['count'] ?? 0;
          if (currentCount <= 1) {
            batch.delete(tagRef);
          } else {
            batch.update(tagRef, {'count': FieldValue.increment(-1)});
          }
        }
      }
    }

    for (var tag in newHashtags) {
      if (!oldHashtags.contains(tag)) {
        final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        final tagRef = firebaseService.firestore.collection('hashtags').doc(cleanTag);

        final snapshot = await tagRef.get();
        if (snapshot.exists) {
          batch.update(tagRef, {'count': FieldValue.increment(1)});
        } else {
          batch.set(tagRef, {'count': 1});
        }
      }
    }

    await batch.commit();
  }

  Future<bool> hasUserLikedPost({
    required String postId,
    required String userId,
  }) async {
    try {
      final likeDoc = await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking if user liked post: $e');
      return false;
    }
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = firebaseService.firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      final likeDoc = await likeRef.get();
      final bool isLiked = likeDoc.exists;

      final batch = firebaseService.firestore.batch();

      if (isLiked) {
        batch.delete(likeRef);
        batch.update(postRef, {
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        batch.set(likeRef, {
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {
          'likeCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  Future<List<String>> getLikedUserIds({
    required String postId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      debugPrint('Error getting liked user ids: $e');
      return [];
    }
  }

  Future<List<PostModel>> getFeedPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = firebaseService.firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting feed posts: $e');
      return [];
    }
  }

  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final query = firebaseService.firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('Không có bài viết nào.');
        return [];
      }

      return snapshot.docs.map((doc) {
        try {
          return PostModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('Lỗi khi ánh xạ post ${doc.id}: $e');
          return null;
        }
      }).whereType<PostModel>().toList();
    } catch (e) {
      debugPrint('Lỗi khi lấy bài viết người dùng: $e');
      return [];
    }
  }

  Future<List<PostModel>> getPostsByHashtag(String hashtag) async {
    try {
      final cleanTag = hashtag.startsWith('#') ? hashtag : '#$hashtag';
      final snapshot = await firebaseService.firestore
          .collection('posts')
          .where('hashtags', arrayContains: cleanTag)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting posts by hashtag: $e');
      return [];
    }
  }

  Future<List<String>> searchHashtags(String keyword) async {
    try {
      final snapshot = await firebaseService.firestore.collection('hashtags').get();
      final lowerKeyword = keyword.toLowerCase();

      final results = snapshot.docs
          .map((doc) => doc.id)
          .where((tag) => tag.toLowerCase().contains(lowerKeyword))
          .toList();

      return results;
    } catch (e) {
      debugPrint('Error searching hashtags: $e');
      return [];
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      final snapshot = await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!snapshot.exists) return null;

      return PostModel.fromFirestore(snapshot);
    } catch (e) {
      debugPrint('Error getting post by id: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPopularHashtags({int limit = 10}) async {
    try {
      final snapshot = await firebaseService.firestore
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

  Future<void> deletePost(String postId) async {
    try {
      final postSnapshot = await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!postSnapshot.exists) return;

      final post = PostModel.fromFirestore(postSnapshot);

      final likesSnapshot = await firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();

      final batch = firebaseService.firestore.batch();

      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(firebaseService.firestore.collection('posts').doc(postId));

      await batch.commit();
      await _decrementHashtagCounts(post.hashtags);

      for (var mediaUrl in post.mediaUrls) {
        try {
          final ref = firebaseService.storage.refFromURL(mediaUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting media file: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> _decrementHashtagCounts(List<String> hashtags) async {
    final batch = firebaseService.firestore.batch();

    for (var tag in hashtags) {
      final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
      final tagRef = firebaseService.firestore.collection('hashtags').doc(cleanTag);

      final snapshot = await tagRef.get();
      if (snapshot.exists) {
        final currentCount = snapshot.data()?['count'] ?? 0;
        if (currentCount <= 1) {
          batch.delete(tagRef);
        } else {
          batch.update(tagRef, {
            'count': FieldValue.increment(-1),
          });
        }
      }
    }

    await batch.commit();
  }

  Stream<bool> likeStatusStream({
    required String postId,
    required String userId,
  }) {
    return firebaseService.firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<List<CommentModel>> getPostComments(
      String postId, {
      int limit = 20,
        DocumentSnapshot? lastDocument,
      }) async {
    try {
      Query query = firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting post comments: $e');
      return [];
    }
  }

  Future<String> addComment({
    required String postId,
    required String userId,
    required String text,
    String? username,
    String? userAvatar,
  }) async {
    try {
      final commentRef = firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      final comment = CommentModel(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        text: text,
        createdAt: DateTime.now(),
        username: username,
        userAvatar: userAvatar,
      );

      final batch = firebaseService.firestore.batch();

      batch.set(commentRef, comment.toMap());
      batch.update(
        firebaseService.firestore.collection('posts').doc(postId),
        {'commentCount': FieldValue.increment(1)},
      );

      await batch.commit();
      return commentRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }
}