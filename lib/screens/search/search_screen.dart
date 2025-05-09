import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/screens/stories/stories_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;

  void onSearchSubmitted(String query) {
    setState(() {
      isShowUsers = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = List.generate(
      30,
          (index) => 'https://picsum.photos/seed/image$index/200/200',
    );
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: onSearchSubmitted,
          onChanged: (value) {
            if (value.isEmpty && isShowUsers) {
              setState(() {
                isShowUsers = false;
              });
            }
          },
        ),
        backgroundColor: Colors.black,
        elevation: 1,
      ),
      body: isShowUsers? FutureBuilder(
          future: FirebaseFirestore.instance.collection('users')
          .where('username', isGreaterThanOrEqualTo: searchController.text)
              .get(),
          builder: (context, snapshot) {
            if(!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(),);
            }
            final QuerySnapshot<Map<String, dynamic>> data =
            snapshot.data as QuerySnapshot<Map<String, dynamic>>;
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> users = data.docs;
            // if(users.isEmpty) {
            //
            // }
            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data();
                  return ListTile(
                    leading: (user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty)
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(user['avatar_url']),
                    )
                        : const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),

                    title: Text(
                      user['username'],
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {

                    },
                  );
                },
            );
          },
      )
      : Padding(
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
            );
          },
        ),
      ),
    );
  }
}
