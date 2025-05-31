import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../services/firebase_service.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? userAvatar;
  final String? username;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.userAvatar,
    this.username,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userAvatar: data['userAvatar'],
      username: data['username'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
      'userAvatar': userAvatar,
      'username': username,
    };
  }
}

class CommentModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();

  static Future<List<CommentModel>> getCommentsForPost({
    required String postId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firebaseService.firestore
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

  static Future<DocumentSnapshot?> getCommentDoc({
    required String postId,
    required String commentId,
  }) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();
      return doc.exists ? doc : null;
    } catch (e) {
      debugPrint('Error getting comment doc: $e');
      return null;
    }
  }

  static Future<String> addComment({
    required String postId,
    required String userId,
    required String text,
    String? username,
    String? userAvatar,
  }) async {
    try {
      final commentRef = _firebaseService.firestore
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

      final batch = _firebaseService.firestore.batch();

      batch.set(commentRef, comment.toMap());
      batch.update(
        _firebaseService.firestore.collection('posts').doc(postId),
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