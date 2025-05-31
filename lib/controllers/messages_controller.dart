import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/post_model.dart';
import '../services/firebase_service.dart';
import '../models/message_model.dart';
import '../models/user_chat_model.dart';

class MessagesController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;
  String currentUserId = '';
  String currentUsername = '';
  int userPostCount = 0;
  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';
  List<File> selectedImages = [];
  bool isUploading = false;

  @override
  void onInit() {
    super.onInit();
    currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      _firestore.collection('users').doc(currentUserId).snapshots().listen((doc) {
        if (doc.exists) {
          currentUsername = doc.data()?['username'] ?? '';
          update();
        }
      });
    }
  }

  void updateSearchKeyword(String keyword) {
    searchKeyword = keyword.toLowerCase();
    update();
  }

  void addImages(List<File> images) {
    selectedImages.addAll(images);
    update(['selected_images']);
  }

  void removeImageAt(int index) {
    selectedImages.removeAt(index);
    update(['selected_images']);
  }

  void clearImages() {
    selectedImages.clear();
    update(['selected_images']);
  }

  void setUploading(bool uploading) {
    isUploading = uploading;
    update(['uploading_status']);
  }

  Future<void> countUserPosts(String ownerId) async {
    try {
      final postsMap = await PostModelSnapshot.getMapPostByUser(ownerId);
      userPostCount = postsMap.length;
      update(['user_post_count']);
    } catch (e) {
      if (kDebugMode) print('Lỗi đếm bài viết: $e');
      userPostCount = 0;
      update(['user_post_count']);
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return MessageModelSnapshot.getMessagesStream(conversationId);
  }

  Future<void> sendMessage(
      String conversationId,
      MessageModel msg, {
        List<String> imageUrls = const [],
      }) async {
    await MessageModelSnapshot.sendMessage(conversationId, msg, imageUrls: imageUrls);
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await MessageModelSnapshot.deleteMessage(conversationId, messageId);
  }

  Future<void> deleteConversation(String currentUserId, String otherUserId) async {
    await MessageModelSnapshot.deleteConversation(currentUserId, otherUserId);
  }

  Stream<List<UserChatModel>> getRecentConversations(String currentUserId) {
    return UserChatModelSnapshot.getRecentConversations(currentUserId);
  }

  Stream<List<UserChatModel>> getFilteredSuggestionsStream(String currentUserId) {
    return UserChatModelSnapshot.getFilteredSuggestionsStream(currentUserId);
  }

  Stream<List<UserChatModel>> getRecentConversationsStream() {
    return getRecentConversations(currentUserId);
  }

  Stream<List<UserChatModel>> getSuggestionsStream() {
    return getFilteredSuggestionsStream(currentUserId);
  }

  Future<void> deleteConversationAndMessages(String otherUserId) async {
    if (userId != null) {
      await deleteConversation(userId!, otherUserId);
    }
  }

  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<List<String>> uploadImages({
    required List<File> images,
    required String path,
  }) async {
    List<String> imageUrls = [];

    for (var image in images) {
      final url = await _firebaseService.uploadImage(image: image, path: '$path/${DateTime.now().millisecondsSinceEpoch}');
      imageUrls.add(url);
    }

    return imageUrls;
  }

  bool _isEmojiVisible = false;
  bool get isEmojiVisible => _isEmojiVisible;

  void toggleEmojiKeyboard() {
    _isEmojiVisible = !_isEmojiVisible;
    update(['emoji']);
  }

  void hideEmojiKeyboard() {
    if (_isEmojiVisible) {
      _isEmojiVisible = false;
      update(['emoji']);
    }
  }

  Future<void> addOrRemoveReaction(String conversationId, String messageId, String reactionKey) async {
    await MessageModelSnapshot.addOrRemoveReaction(conversationId, messageId, reactionKey);
  }

  String formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
