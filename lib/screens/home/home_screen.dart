import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';


import '../../services/firebase_service.dart';
import '../stories/stories_screen.dart';
import '../stories/helper_permission.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, String>> posts = [
    {
      'username': 'john_doe',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'image': 'https://picsum.photos/500/500?random=1',
      'caption': 'A beautiful day in the city ☀️',
    },
    {
      'username': 'sarah_123',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'image': 'https://picsum.photos/500/500?random=2',
      'caption': 'Love this view 💙',
    },
    {
      'username': 'flutter_dev',
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'image': 'https://picsum.photos/500/500?random=3',
      'caption': 'Coding with coffee ☕',
    },
  ];

  List<bool> liked = [];
  List<bool> showHeart = [];

  @override
  void initState() {
    super.initState();
    liked = List<bool>.filled(posts.length, false);
    showHeart = List<bool>.filled(posts.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return buildStorySection();
        }
        final post = posts[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(post['avatar']!),
              ),
              title: Text(post['username']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.more_vert),
            ),
            // Image with double-tap like
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    setState(() {
                      liked[index - 1] = true;
                      showHeart[index - 1] = true;
                    });
                    Future.delayed(const Duration(milliseconds: 600), () {
                      setState(() {
                        showHeart[index - 1] = false;
                      });
                    });
                  },
                  child: Image.network(
                    post['image']!,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: showHeart[index - 1] ? 1.0 : 0.0,
                  child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                ),
              ],
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    liked[index - 1] ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                    size: 24,
                    color: liked[index - 1] ? Colors.pinkAccent : null,
                  ),
                  const SizedBox(width: 16),
                  const Icon(FontAwesomeIcons.comment, size: 24),
                  const SizedBox(width: 16),
                  const Icon(FontAwesomeIcons.paperPlane, size: 24),
                  const Spacer(),
                  const Icon(FontAwesomeIcons.bookmark, size: 24),
                ],
              ),
            ),
            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: post['username']! + ' ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post['caption']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget buildStorySection() {
    XFile? _xFile;
    final currentUser = {
      'avatar': '',
      'username': 'mainuser',
      'isCurrentUser': true,
    };

    final stories = [
      currentUser,
      ...List.generate(10, (index) => {
        'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
        'username': 'user$index',
        'isCurrentUser': false,
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final story = stories[index];
            final isCurrentUser = (story['isCurrentUser'] as bool?) ?? false;

            return GestureDetector(
              onTap: () async {
                if (isCurrentUser) {
                  final hasPermission = await requestPermission(Permission.photos);
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không có quyền truy cập ảnh.')),
                    );
                    return;
                  }

                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    final file = File(pickedFile.path);
                    final userId = FirebaseService().userId;
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final storagePath = 'stories/$userId/$timestamp.jpg';

                    try {
                      final downloadUrl = await FirebaseService().uploadImage(
                        image: file,
                        path: storagePath,
                      );

                      await FirebaseService().createDocument(
                        collection: 'stories',
                        data: {
                          'userId': userId,
                          'imageUrl': downloadUrl,
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã đăng story thành công")),
                      );

                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi khi upload: $e")),
                      );
                    }
                  } else {
                    debugPrint("Người dùng hủy đăng story");
                  }
                }
              },


              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isCurrentUser ? Colors.grey : Colors.pinkAccent,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(story['avatar'] as String),
                        ),
                      ),
                      if (isCurrentUser)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.add, size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story['username'] as String,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


}
