import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  bool isShowUsers = false;
  bool isShowHashtagPosts = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hashtagPosts = [];

  void onSearchSubmitted(String query) async {
    if (query.startsWith('#')) {
      setState(() {
        isShowUsers = false;
        isShowHashtagPosts = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('hashtags', arrayContains: query.trim())
          .get();

      setState(() {
        hashtagPosts = snapshot.docs;
      });
    } else {
      setState(() {
        isShowUsers = query.isNotEmpty;
        isShowHashtagPosts = false;
      });
    }
  }

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
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: TextFormField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white70),
              ),
              onFieldSubmitted: onSearchSubmitted,
            ),
          ),
        ),
      ),
      body: isShowUsers
          ? buildUserResults()
          : isShowHashtagPosts
          ? buildHashtagPosts()
          : buildGridPlaceholder(),
    );
  }

  Widget buildUserResults() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('username',
          isGreaterThanOrEqualTo: searchController.text)
          .where('username',
          isLessThanOrEqualTo: searchController.text + '\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as QuerySnapshot<Map<String, dynamic>>;
        final users = data.docs;

        if (users.isEmpty) {
          return Center(
            child: Text('Không tìm thấy người dùng',
                style: TextStyle(color: Colors.white)),
          );
        }

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
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(user['username'],
                  style: TextStyle(color: Colors.white)),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  Widget buildHashtagPosts() {
    if (hashtagPosts.isEmpty) {
      return Center(
        child: Text('Không có bài viết với hashtag này',
            style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: hashtagPosts.length,
      itemBuilder: (context, index) {
        final post = hashtagPosts[index].data();
        return ListTile(
          title: Text(post['caption'] ?? '',
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            (post['hashtags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .join(', ') ??
                '',
            style: TextStyle(color: Colors.white70),
          ),
          leading: post['image_url'] != null
              ? Image.network(post['image_url'], width: 60, fit: BoxFit.cover)
              : null,
        );
      },
    );
  }

  Widget buildGridPlaceholder() {
    final List<String> imageUrls = List.generate(
      30,
          (index) => 'https://picsum.photos/seed/image$index/200/200',
    );

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        itemCount: imageUrls.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
