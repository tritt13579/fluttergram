import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';

class MessagesController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;

  String currentUserId = '';
  String currentUsername = '';
  int userPostCount = 0;

  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';

  List<File> selectedImages = [];
  bool isUploading = false;
  bool _isEmojiVisible = false;
  bool get isEmojiVisible => _isEmojiVisible;

  /// --- OnInit chỉ giữ việc lấy thông tin người dùng (không chạm trực tiếp Firestore).
  @override
  void onInit() {
    super.onInit();
    currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      // Nếu bạn muốn lắng nghe thay đổi username, có thể viết một hàm riêng sử dụng `UserSnapshot` (trong model) để lắng nghe.
      // Ví dụ ở đây mình giả sử bạn đã có cơ chế khác để set currentUsername.
    }
  }

  /// 1. Cập nhật từ khóa tìm kiếm
  void updateSearchKeyword(String keyword) {
    searchKeyword = keyword.toLowerCase();
    update();
  }

  /// 2. Quản lý danh sách ảnh trước khi gửi
  void addImages(List<File> images) {
    selectedImages.addAll(images);
    update(['selected_images']);
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      update(['selected_images']);
    }
  }

  void clearImages() {
    selectedImages.clear();
    update(['selected_images']);
  }

  void setUploading(bool uploading) {
    isUploading = uploading;
    update(['uploading_status']);
  }

  /// 3. Đếm số bài viết của một user (gọi vào class MessageSnapshot)
  Future<void> countUserPosts(String ownerId) async {
    try {
      userPostCount = await MessageSnapshot.countUserPosts(ownerId);
      update(['user_post_count']);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi đếm bài viết: $e');
      }
      userPostCount = 0;
      update(['user_post_count']);
    }
  }

  /// 4. Stream lấy danh sách tin nhắn (đã chuyển vào MessageSnapshot)
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return MessageSnapshot.getMessagesStream(conversationId);
  }

  /// 5. Gửi tin nhắn (đã chuyển vào MessageSnapshot)
  Future<void> sendMessage(
      String conversationId,
      MessageModel msg, {
        List<String> imageUrls = const [],
      }) async {
    await MessageSnapshot.sendMessage(
      conversationId,
      msg,
      imageUrls: imageUrls,
    );
  }

  /// 6. Xóa một tin nhắn
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await MessageSnapshot.deleteMessage(conversationId, messageId);
  }

  /// 7. Xóa cả cuộc trò chuyện (và tin nhắn con) giữa hai user
  Future<void> deleteConversation(String otherUserId) async {
    if (userId != null) {
      await MessageSnapshot.deleteConversation(currentUserId, otherUserId);
    }
  }

  /// 8. Stream danh sách cuộc trò chuyện gần nhất
  Stream<List<UserModel>> getRecentConversationsStream() {
    if (currentUserId.isEmpty) {
      // Trả về stream rỗng nếu chưa có userId
      return const Stream.empty();
    }
    return MessageSnapshot.getRecentConversations(currentUserId);
  }

  /// 9. Stream gợi ý user chưa chat
  Stream<List<UserModel>> getSuggestionsStream() {
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }
    return MessageSnapshot.getFilteredSuggestionsStream(currentUserId);
  }

  /// 10. Xóa conversation và messages (delegated)
  Future<void> deleteConversationAndMessages(String otherUserId) async {
    if (currentUserId.isNotEmpty) {
      await MessageSnapshot.deleteConversationAndMessages(
          currentUserId, otherUserId);
    }
  }

  /// 11. Tạo conversationId
  String getConversationId(String uid1, String uid2) {
    return MessageSnapshot.getConversationId(uid1, uid2);
  }

  /// 12. Upload hình ảnh (truyền vào MessageSnapshot.uploadImages)
  Future<List<String>> uploadImages(
      {required List<File> images, required String path}) async {
    return await MessageSnapshot.uploadImages(images, path);
  }

  /// 13. Thêm hoặc xóa reaction
  Future<void> addOrRemoveReaction(
      String conversationId, String messageId, String reactionKey) async {
    await MessageSnapshot.addOrRemoveReaction(
        conversationId, messageId, reactionKey);
  }

  /// 14. Quản lý hiển thị emoji keyboard
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
}
