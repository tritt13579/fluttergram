import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/layouts/main_layout.dart';
import 'package:get/get.dart';

import '../models/hashtag_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/post_service.dart';
import '../utils/snackbar_utils.dart';

class FinalPostController extends GetxController {
  final List<Uint8List?> mediaList;
  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocusNode = FocusNode();

  final firebaseService = FirebaseService();
  late final PostService postService;
  StreamSubscription<List<String>>? _userSub;
  StreamSubscription<List<String>>? _hashtagSub;
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
    final allHashtags = hashtagRegExp
        .allMatches(captionController.text)
        .map((match) => match.group(1)!)
        .toList();

    if (allHashtags.length > 30) {
      extractedHashtags.value = allHashtags.take(30).toList();
      SnackbarUtils.showWarning('Chỉ được sử dụng tối đa 30 hashtag');
    } else {
      extractedHashtags.value = allHashtags;
    }

    final RegExp mentionRegExp = RegExp(r'@(\w+)');
    extractedTaggedUsers.value = mentionRegExp
        .allMatches(captionController.text)
        .map((match) => match.group(1)!)
        .toList();
  }

  Future<void> fetchUsersByPrefix(String prefix) async {
    _userSub?.cancel();
    _userSub = UserModelSnapshot().usernamesByPrefix(prefix).listen((users) {
      filteredUsers.value = users;
    }, onError: (e) {
      if (kDebugMode) print('Lỗi khi tìm user theo prefix: $e');
      filteredUsers.clear();
    });
  }

  Future<void> fetchHashtagsByPrefix(String prefix) async {
    _hashtagSub?.cancel();
    _hashtagSub = HashtagModelSnapshot.hashtagsByPrefix(prefix).listen((tags) {
      filteredHashtags.value = tags;
    }, onError: (e) {
      if (kDebugMode) print('Lỗi khi tìm hashtag theo prefix: $e');
      filteredHashtags.clear();
    });
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
    try {
      isLoading.value = true;

      final map = await UserModelSnapshot.getMapUserModel();
      final user = map[userId];
      if (user == null) {
        SnackbarUtils.showError('Không tìm thấy thông tin người dùng');
        isLoading.value = false;
        return;
      }
      final String username = user.username;
      final String avatarUrl = user.avatarUrl;

      final String captionText = captionController.text.trim();
      final List<String> hashtags = extractedHashtags
          .map((tag) => '#$tag')
          .toList();

      final List<String> mediaUrls = await postService.uploadMediaFiles(mediaList, userId!);

      if (captionText.isEmpty && mediaUrls.isEmpty) {
        SnackbarUtils.showWarning('Vui lòng nhập caption hoặc chọn ảnh/video');
        isLoading.value = false;
        return;
      }

      await postService.createPost(
        userId: userId!,
        caption: captionText,
        mediaUrls: mediaUrls,
        ownerUsername: username,
        ownerPhotoUrl: avatarUrl,
        hashtags: hashtags,
      );

      Get.offAll(MainLayout());
      SnackbarUtils.showSuccess('Bài viết đã được đăng');
    } catch (e) {
      SnackbarUtils.showError('Không thể đăng bài: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _userSub?.cancel();
    _hashtagSub?.cancel();
    captionController.removeListener(_handleCaptionChanges);
    captionController.dispose();
    captionFocusNode.dispose();
    super.onClose();
  }
}