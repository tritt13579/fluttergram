import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/firebase_service.dart';

enum SearchMode { initial, users, hashtagSuggestions, hashtagPosts }

class SearchFlutterController extends GetxController {
  late final PostService _postService;

  final TextEditingController textEditingController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final Rx<SearchMode> searchMode = SearchMode.initial.obs;
  final RxBool isLoading = false.obs;
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> userResults =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  final RxList<String> hashtagSuggestions = <String>[].obs;
  final RxList<PostModel> hashtagPostsResults = <PostModel>[].obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<PostService>()) {
      Get.lazyPut<PostService>(() => PostService(Get.find<FirebaseService>()));
    }
    _postService = Get.find<PostService>();
    textEditingController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    searchQuery.value = textEditingController.text.trim();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery.value.startsWith('#') && searchQuery.value.length > 1) {
        searchMode.value = SearchMode.hashtagSuggestions;
        _fetchHashtagSuggestions(searchQuery.value);
      } else if (searchQuery.value.isNotEmpty && !searchQuery.value.startsWith('#')) {
        searchMode.value = SearchMode.users;
      } else {
        searchMode.value = SearchMode.initial;
        userResults.clear();
        hashtagSuggestions.clear();
        hashtagPostsResults.clear();
      }
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: searchQuery.value)
        .where('username', isLessThanOrEqualTo: '${searchQuery.value}\uf8ff')
        .get();
  }

  Future<void> _fetchHashtagSuggestions(String query) async {
    if (query.length <= 1) {
      hashtagSuggestions.clear();
      return;
    }
    isLoading.value = true;
    final String keyword = query.substring(1);
    final results = await _postService.searchHashtags(keyword);
    hashtagSuggestions.assignAll(results.map((tag) => '#$tag'));
    isLoading.value = false;
  }

  Future<void> onHashtagSubmitted(String hashtag) async {
    textEditingController.removeListener(_onSearchChanged);
    textEditingController.text = hashtag;
    searchQuery.value = hashtag;
    textEditingController.addListener(_onSearchChanged);

    isLoading.value = true;
    hashtagPostsResults.clear();

    final results = await _postService.getPostsByHashtag(hashtag);
    hashtagPostsResults.assignAll(results);

    searchMode.value = SearchMode.hashtagPosts;
    isLoading.value = false;
  }

  Future<void> onUserSearchSubmitted(String query) async {
    if (query.isEmpty || query.startsWith('#')) return;
    searchMode.value = SearchMode.users;
  }



  @override
  void onClose() {
    textEditingController.removeListener(_onSearchChanged);
    textEditingController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}