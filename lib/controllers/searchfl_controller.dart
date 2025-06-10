import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/hashtag_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

enum SearchMode { initial, users, hashtagSuggestions, hashtagPosts }

class SearchFlutterController extends GetxController {
  final TextEditingController textEditingController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxList<PostModel> trendingPosts = <PostModel>[].obs;
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
    textEditingController.addListener(_onSearchChanged);
    loadTrendingPosts();
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

  Future<List<UserModel>> fetchUsers() {
    return UserModelSnapshot.fetchUserModelsByPrefix(searchQuery.value);
  }

  Future<void> _fetchHashtagSuggestions(String query) async {
    if (query.length <= 1) {
      hashtagSuggestions.clear();
      return;
    }
    isLoading.value = true;
    final String keyword = query.substring(1);
    final results = await HashtagModelSnapshot.hashtagsByPrefix(keyword).first;
    hashtagSuggestions.assignAll(results.map((tag) => '#$tag'));
    isLoading.value = false;
  }

  Future<void> onHashtagSubmitted(String hashtag) async {
    FocusManager.instance.primaryFocus?.unfocus();

    textEditingController.removeListener(_onSearchChanged);
    textEditingController.text = hashtag;
    searchQuery.value = hashtag;
    textEditingController.addListener(_onSearchChanged);

    isLoading.value = true;
    hashtagPostsResults.clear();

    final postMap = await PostModelSnapshot.getMapPostByHashtag(hashtag);
    hashtagPostsResults.assignAll(postMap.values.toList());

    searchMode.value = SearchMode.hashtagPosts;
    isLoading.value = false;
  }

  Future<void> onUserSearchSubmitted(String query) async {
    if (query.isEmpty || query.startsWith('#')) return;
    searchMode.value = SearchMode.users;
  }

  Future<void> loadTrendingPosts() async {
    isLoading.value = true;
    final postMap = await PostModelSnapshot.getMapPost();
    final posts = postMap.values
        .toList()
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    trendingPosts.assignAll(posts.take(20));
    isLoading.value = false;
  }

  @override
  void onClose() {
    textEditingController.removeListener(_onSearchChanged);
    textEditingController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}