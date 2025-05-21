import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../screens/stories/add_stories.dart';

class StoryCircle extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final bool isCurrentUser;

  const StoryCircle({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.isCurrentUser,
  });

  Future<void> _pickAndNavigate() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final image = File(picked.path);
      Get.to(() => AddStoryScreen(image: image, avatarUrl: avatarUrl, username: username));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentUser ? _pickAndNavigate : null,
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
                  backgroundImage: NetworkImage(avatarUrl),
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
          Text(username, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
