import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';
import '../services/firebase_service.dart';
import '../services/post_service.dart';

class FinalPostController extends GetxController {
  final List<Uint8List?> mediaList;
  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocusNode = FocusNode();

  final firebaseService = FirebaseService();
  late final PostService postService;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final RxString caption = ''.obs;
  final RxList<String> extractedHashtags = <String>[].obs;
  final RxList<String> extractedTaggedUsers = <String>[].obs;

  final RxBool showHashtagSuggestions = false.obs;
  final RxBool showUserSuggestions = false.obs;
  final RxString searchPrefix = ''.obs;
  final RxList<String> filteredHashtags = <String>[].obs;
  final RxList<String> filteredUsers = <String>[].obs;
  final RxBool isLoading = false.obs;

  String? get userId => auth.currentUser?.uid;

  FinalPostController({required this.mediaList});

  @override
  void onInit() {
    super.onInit();
    captionController.addListener(_handleCaptionChanges);

    postService = PostService(firebaseService);
  }

  void _handleCaptionChanges() {
    caption.value = captionController.text;
    _extractMentionsAndHashtags();
    _checkForSuggestions();
  }

  void _extractMentionsAndHashtags() {
    final RegExp hashtagRegExp = RegExp(r'#(\w+)');
    extractedHashtags.value = hashtagRegExp
        .allMatches(captionController.text)
        .map((match) => match.group(1)!)
        .toList();

    final RegExp mentionRegExp = RegExp(r'@(\w+)');
    extractedTaggedUsers.value = mentionRegExp
        .allMatches(captionController.text)
        .map((match) => match.group(1)!)
        .toList();
  }

  Future<void> fetchUsersByPrefix(String prefix) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .startAt([prefix])
          .endAt(['$prefix\uf8ff'])
          .limit(10)
          .get();

      filteredUsers.value = snapshot.docs
          .map((doc) => doc['username']?.toString() ?? '')
          .where((username) => username.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tìm user theo prefix: $e');
      }
      filteredUsers.clear();
    }
  }

  Future<void> fetchHashtagsByPrefix(String prefix) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hashtags')
          .orderBy(FieldPath.documentId)
          .startAt([prefix])
          .endAt(['$prefix\uf8ff'])
          .limit(10)
          .get();

      filteredHashtags.value = snapshot.docs
          .map((doc) => doc.id)
          .where((tag) => tag.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tìm hashtag theo prefix: $e');
      }
      filteredHashtags.clear();
    }
  }

  void _checkForSuggestions() {
    showHashtagSuggestions.value = false;
    showUserSuggestions.value = false;
    searchPrefix.value = '';

    String text = captionController.text;
    int cursorPos = captionController.selection.end;

    if (cursorPos <= 0 || cursorPos > text.length) return;

    int startPos = cursorPos - 1;
    while (startPos >= 0 && text[startPos] != ' ' && text[startPos] != '\n') {
      startPos--;
    }
    startPos++;

    if (startPos < cursorPos) {
      String currentWord = text.substring(startPos, cursorPos);

      if (currentWord.startsWith('#')) {
        String searchTerm = currentWord.substring(1).toLowerCase();
        searchPrefix.value = searchTerm;

        fetchHashtagsByPrefix(searchTerm);
        showHashtagSuggestions.value = true;
      }
      else if (currentWord.startsWith('@')) {
        String searchTerm = currentWord.substring(1).toLowerCase();
        searchPrefix.value = searchTerm;

        fetchUsersByPrefix(searchTerm);
        showUserSuggestions.value = true;
      }
    }
  }

  void insertSuggestion(String suggestion, {required bool isHashtag}) {
    String text = captionController.text;
    int cursorPos = captionController.selection.end;

    int startPos = cursorPos - 1;
    while (startPos >= 0 && text[startPos] != ' ' && text[startPos] != '\n') {
      startPos--;
    }
    startPos++;

    String prefix = isHashtag ? '#' : '@';
    String newText = '${text.substring(0, startPos)}$prefix$suggestion ${text.substring(cursorPos)}';

    captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: startPos + suggestion.length + 2),
    );

    showHashtagSuggestions.value = false;
    showUserSuggestions.value = false;
  }

  Future<void> publishPost() async {
    if (userId == null) {
      showError('Bạn cần đăng nhập để đăng bài');
      return;
    }

    try {
      isLoading.value = true;

      final String captionText = captionController.text.trim();
      final List<String> hashtags = extractedHashtags
          .map((tag) => '#$tag')
          .toList();
      final List<String> mediaUrls = await postService.uploadMediaFiles(mediaList, userId!);

      if (captionText.isEmpty && mediaUrls.isEmpty) {
        showWarning('Vui lòng nhập caption hoặc chọn ảnh/video');
        isLoading.value = false;
        return;
      }

      await postService.createPost(
        userId: userId!,
        caption: captionText,
        mediaUrls: mediaUrls,
        hashtags: hashtags,
      );

      Get.offAll(MainLayout());
      showSuccess('Bài viết đã được đăng');
    } catch (e) {
      showError('Không thể đăng bài: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void showError(String message) {
    Get.snackbar('Lỗi', message,
        backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  void showWarning(String message) {
    Get.snackbar('Thiếu nội dung', message,
        backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  void showSuccess(String message) {
    Get.snackbar('Thành công', message,
        backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    captionController.removeListener(_handleCaptionChanges);
    captionController.dispose();
    captionFocusNode.dispose();
    super.onClose();
  }
}