import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firebase_service.dart';
import '../screens/stories/helper_permission.dart';
import 'story_circle.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  final currentUser = {
    'avatar': 'https://i.pravatar.cc/150?img=1',
    'username': 'mainuser',
    'isCurrentUser': true,
  };

  late final List<Map<String, dynamic>> stories;

  @override
  void initState() {
    super.initState();
    stories = [
      currentUser,
      ...List.generate(10, (index) => {
        'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
        'username': 'user$index',
        'isCurrentUser': false,
      }),
    ];
  }

  Future<void> _handleAddStory(BuildContext context) async {
    final hasPermission = await requestPermission(Permission.photos);
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập ảnh.')),
        );
      }
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

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã đăng story thành công")),
          );
        }

        setState(() {});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi upload: $e")),
          );
        }
      }
    } else {
      debugPrint("Người dùng hủy đăng story");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            final isCurrentUser = story['isCurrentUser'] as bool;

            return StoryCircle(
              avatarUrl: story['avatar'] as String,
              username: story['username'] as String,
              isCurrentUser: isCurrentUser,
              onTap: isCurrentUser ? () => _handleAddStory(context) : null,
            );
          },
        ),
      ),
    );
  }
}