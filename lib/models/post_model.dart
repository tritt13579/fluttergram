import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';

class PostModel {
  final String id;
  final String ownerId;
  final String? ownerUsername;
  final String? ownerPhotoUrl;
  final String caption;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.ownerId,
    this.ownerUsername,
    this.ownerPhotoUrl,
    required this.caption,
    required this.mediaUrls,
    required this.hashtags,
    required this.likeCount,
    required this.commentCount,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'ownerPhotoUrl': ownerPhotoUrl,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'hashtags': hashtags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerUsername: map['ownerUsername'],
      ownerPhotoUrl: map['ownerPhotoUrl'],
      caption: map['caption'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PostModel.fromMap(data);
  }

  PostModel copyWith({
    String? id,
    String? ownerId,
    String? ownerUsername,
    String? ownerPhotoUrl,
    String? caption,
    List<String>? mediaUrls,
    List<String>? hashtags,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      caption: caption ?? this.caption,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      hashtags: hashtags ?? this.hashtags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PostModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();
  static final Uuid _uuid = const Uuid();

  // Get all posts as Map
  static Future<Map<String, PostModel>> getMapPost() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      Map<String, PostModel> postsMap = {};
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        postsMap[post.id] = post;
      }
      return postsMap;
    } catch (e) {
      debugPrint('Error getting posts map: $e');
      return {};
    }
  }

  static Future<Map<String, PostModel>> getMapPostAfter({
    required DateTime lastCreatedAt,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfter([lastCreatedAt])
          .limit(limit)
          .get();

      Map<String, PostModel> postsMap = {};
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        postsMap[post.id] = post;
      }
      return postsMap;
    } catch (e) {
      debugPrint('Error getting paginated posts map: $e');
      return {};
    }
  }

  // Get user posts as Map
  static Future<Map<String, PostModel>> getMapPostByUser(String userId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      Map<String, PostModel> postsMap = {};
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        postsMap[post.id] = post;
      }
      return postsMap;
    } catch (e) {
      debugPrint('Error getting user posts map: $e');
      return {};
    }
  }

  // Get posts by hashtag as Map
  static Future<Map<String, PostModel>> getMapPostByHashtag(String hashtag) async {
    try {
      final cleanTag = hashtag.startsWith('#') ? hashtag : '#$hashtag';
      final snapshot = await _firebaseService.firestore
          .collection('posts')
          .where('hashtags', arrayContains: cleanTag)
          .orderBy('createdAt', descending: true)
          .get();

      Map<String, PostModel> postsMap = {};
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        postsMap[post.id] = post;
      }
      return postsMap;
    } catch (e) {
      debugPrint('Error getting hashtag posts map: $e');
      return {};
    }
  }

  static Stream<bool> likeStatusStream({
    required String postId,
    required String userId,
  }) {
    return _firebaseService.firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Insert new post
  static Future<String> insert(PostModel post, List<Uint8List?> mediaList) async {
    try {
      final postRef = _firebaseService.firestore.collection('posts').doc();

      // Upload media files
      List<String> mediaUrls = [];
      for (var media in mediaList) {
        if (media != null) {
          final url = await _uploadMedia(media, post.ownerId);
          mediaUrls.add(url);
        }
      }

      // Extract hashtags
      final hashtags = _extractHashtags(post.caption);

      final newPost = post.copyWith(
        id: postRef.id,
        mediaUrls: mediaUrls,
        hashtags: hashtags,
        createdAt: DateTime.now(),
      );

      await postRef.set(newPost.toMap());
      await _updateHashtagCounts(hashtags);

      return postRef.id;
    } catch (e) {
      debugPrint('Error inserting post: $e');
      rethrow;
    }
  }

  // Update post
  static Future<void> update(PostModel post) async {
    try {
      final postDoc = await _firebaseService.firestore
          .collection('posts')
          .doc(post.id)
          .get();

      if (!postDoc.exists) throw Exception('Post does not exist');

      final currentPost = PostModel.fromFirestore(postDoc);
      final oldHashtags = currentPost.hashtags;
      final newHashtags = _extractHashtags(post.caption);

      await _firebaseService.firestore
          .collection('posts')
          .doc(post.id)
          .update({
        'caption': post.caption,
        'hashtags': newHashtags,
      });

      await _updateHashtagCountsForEdit(oldHashtags, newHashtags);
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  // Delete post
  static Future<void> delete(String postId) async {
    try {
      final postSnapshot = await _firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!postSnapshot.exists) return;

      final post = PostModel.fromFirestore(postSnapshot);

      // Delete likes subcollection
      final likesSnapshot = await _firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();

      final batch = _firebaseService.firestore.batch();

      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firebaseService.firestore.collection('posts').doc(postId));
      await batch.commit();

      await _decrementHashtagCounts(post.hashtags);

      // Delete media files
      for (var mediaUrl in post.mediaUrls) {
        try {
          final ref = _firebaseService.storage.refFromURL(mediaUrl);
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

  // Toggle like
  static Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firebaseService.firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      final likeDoc = await likeRef.get();
      final bool isLiked = likeDoc.exists;

      final batch = _firebaseService.firestore.batch();

      if (isLiked) {
        batch.delete(likeRef);
        batch.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        batch.set(likeRef, {
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {'likeCount': FieldValue.increment(1)});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  // Check if user liked post
  static Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final likeDoc = await _firebaseService.firestore
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

  // Private helper methods
  static Future<String> _uploadMedia(Uint8List media, String userId) async {
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

  static Future<List<String>> uploadMediaList(List<Uint8List?> mediaList, String userId) async {
    List<String> mediaUrls = [];
    for (var media in mediaList) {
      if (media != null) {
        final url = await _uploadMedia(media, userId);
        mediaUrls.add(url);
      }
    }
    return mediaUrls;
  }

  static List<String> _extractHashtags(String caption) {
    final RegExp hashtagRegExp = RegExp(r'#(\w+)');
    return hashtagRegExp
        .allMatches(caption)
        .map((match) => '#${match.group(1)!}')
        .toList();
  }

  static Future<void> _updateHashtagCounts(List<String> hashtags) async {
    final batch = _firebaseService.firestore.batch();

    for (var tag in hashtags) {
      final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
      final tagRef = _firebaseService.firestore.collection('hashtags').doc(cleanTag);

      final snapshot = await tagRef.get();
      if (snapshot.exists) {
        batch.update(tagRef, {'count': FieldValue.increment(1)});
      } else {
        batch.set(tagRef, {'count': 1});
      }
    }

    await batch.commit();
  }

  static Future<void> _updateHashtagCountsForEdit(
      List<String> oldHashtags,
      List<String> newHashtags,
      ) async {
    final batch = _firebaseService.firestore.batch();

    // Decrement old hashtags
    for (var tag in oldHashtags) {
      if (!newHashtags.contains(tag)) {
        final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        final tagRef = _firebaseService.firestore.collection('hashtags').doc(cleanTag);

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

    // Increment new hashtags
    for (var tag in newHashtags) {
      if (!oldHashtags.contains(tag)) {
        final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        final tagRef = _firebaseService.firestore.collection('hashtags').doc(cleanTag);

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

  static Future<void> _decrementHashtagCounts(List<String> hashtags) async {
    final batch = _firebaseService.firestore.batch();

    for (var tag in hashtags) {
      final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
      final tagRef = _firebaseService.firestore.collection('hashtags').doc(cleanTag);

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

    await batch.commit();
  }
}