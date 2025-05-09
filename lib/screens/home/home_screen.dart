import 'package:flutter/material.dart';
import '../../widgets/post_item.dart';
import '../../widgets/stories_section.dart';

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

  void toggleLike(int index) {
    setState(() {
      liked[index] = !liked[index];
    });
  }

  void showHeartAnimation(int index) {
    setState(() {
      liked[index] = true;
      showHeart[index] = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          showHeart[index] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const StoriesSection();
        }
        final postIndex = index - 1;
        final post = posts[postIndex];
        return PostItem(
          post: post,
          isLiked: liked[postIndex],
          showHeart: showHeart[postIndex],
          onDoubleTap: () => showHeartAnimation(postIndex),
          onLikeToggle: () => toggleLike(postIndex),
        );
      },
    );
  }
}