import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/searchfl_controller.dart';
import '../../widgets/post_item.dart';
import '../profile/profile_screen.dart';


class SearchScreen extends GetView<SearchFlutterController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: TextFormField(
              controller: controller.textEditingController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white70),
              ),
              onFieldSubmitted: (value) {
                if (value.startsWith('#')) {
                  controller.onHashtagSubmitted(value);
                } else {
                  controller.onUserSearchSubmitted(value);
                }
              },
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.searchMode.value != SearchMode.hashtagSuggestions) {
          return const Center(child: CircularProgressIndicator());
        }

        switch (controller.searchMode.value) {
          case SearchMode.initial:
            return _buildGridPlaceholder();
          case SearchMode.users:
            return _buildUserResults();
          case SearchMode.hashtagSuggestions:
            return _buildHashtagSuggestions();
          case SearchMode.hashtagPosts:
            return _buildHashtagPosts();
        }
      }),
    );
  }

  Widget _buildUserResults() {
    if (controller.searchQuery.value.isEmpty || controller.searchQuery.value.startsWith('#')) {
      return _buildGridPlaceholder();
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: controller.fetchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && controller.userResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Không tìm thấy người dùng',
                style: TextStyle(color: Colors.white)),
          );
        }

        final users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data();
            return ListTile(
              leading: (user['avatar_url'] != null &&
                  user['avatar_url'].toString().isNotEmpty)
                  ? CircleAvatar(
                backgroundImage: NetworkImage(user['avatar_url']),
              )
                  : CircleAvatar(
                backgroundColor: Colors.grey,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(user['username'] ?? 'N/A',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                //chuyen huong Profile
              },
            );
          },
        );
      },
    );
  }


  Widget _buildHashtagSuggestions() {
    if (controller.isLoading.value && controller.hashtagSuggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.hashtagSuggestions.isEmpty && controller.searchQuery.value.length > 1) {
      return const Center(
          child: Text('Không tìm thấy hashtag nào',
              style: TextStyle(color: Colors.white)));
    }
    if (controller.hashtagSuggestions.isEmpty) {
      return _buildGridPlaceholder();
    }

    return ListView.builder(
      itemCount: controller.hashtagSuggestions.length,
      itemBuilder: (context, index) {
        final tag = controller.hashtagSuggestions[index];
        return ListTile(
          leading: const Icon(Icons.tag, color: Colors.white70),
          title: Text(tag, style: const TextStyle(color: Colors.white)),
          onTap: () {
            controller.onHashtagSubmitted(tag);
          },
        );
      },
    );
  }

  Widget _buildHashtagPosts() {
    if (controller.hashtagPostsResults.isEmpty) {
      return const Center(
        child: Text('Không có bài viết với hashtag này',
            style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      itemCount: controller.hashtagPostsResults.length,
      itemBuilder: (context, index) {
        final post = controller.hashtagPostsResults[index];

        final bool isLiked = false;
        final bool showHeart = false;
        return PostItem(
          post: post,
          isLiked: isLiked,
          showHeart: showHeart,
          onDoubleTap: () {},
          onLikeToggle: () {},
          onCommentTap: () {},
          onProfileTap: () {},
        );
      },
    );
  }

  Widget _buildGridPlaceholder() {
    final List<String> imageUrls = List.generate(
      30,
          (index) => 'https://picsum.photos/seed/image$index/200/200',
    );
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        itemCount: imageUrls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
            },
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }
}