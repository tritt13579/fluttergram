import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firebase_service.dart';
import '../../utils/app_permissions.dart';
import 'story_circle.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  List<Map<String, dynamic>> stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<Map<String, dynamic>> _fetchCurrentUserInfo() async {
    final userId = FirebaseService().userId;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data()!;
      return {
        'avatar': data['avatar_url'] ?? '',
        'username': data['username'] ?? '',
        'isCurrentUser': true,
      };
    } else {
      throw Exception("Không tìm thấy người dùng");
    }
  }

  Future<void> _loadStories() async {
    try {
      final currentUserInfo = await _fetchCurrentUserInfo();

      setState(() {
        stories = [
          currentUserInfo,
          ...List.generate(10, (index) => {
            'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
            'username': 'user$index',
            'isCurrentUser': false,
          }),
        ];
      });
    } catch (e) {
      debugPrint('Lỗi khi tải user: $e');
    }
  }

  Future<void> _handleAddStory(BuildContext context) async {
    final hasPermission = await AppPermissions.requestMediaPermissions();
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
    if (stories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
            );
          },
        ),
      ),
    );
  }
}
