import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../stories/stories_screen.dart';

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
    final stories = List.generate(10, (index) => {
      'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
      'username': 'user$index',
    });

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
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoriesScreen(
                      username: story['username']!,
                      avatarUrl: story['avatar']!,
                      imageUrl: 'https://picsum.photos/800/1400?random=$index',
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pinkAccent, width: 2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(story['avatar']!),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story['username']!,
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
