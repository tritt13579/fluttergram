import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/searchfl_controller.dart';
import '../../widgets/search_function/search_input.dart';
import '../../widgets/search_function/search_support.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SearchFlutterController controller = Get.put(SearchFlutterController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: SearchInput(controller: controller),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.searchMode.value != SearchMode.hashtagSuggestions) {
          return const Center(child: CircularProgressIndicator());
        }

        switch (controller.searchMode.value) {
          case SearchMode.initial:
            return buildGridPlaceholder(controller.trendingPosts);
          case SearchMode.users:
            return buildUserResults(controller);
          case SearchMode.hashtagSuggestions:
            return buildHashtagSuggestions(controller);
          case SearchMode.hashtagPosts:
            return buildHashtagPosts(controller);
        }
      }),
    );
  }
}