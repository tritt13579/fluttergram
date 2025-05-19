import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/firebase_service.dart';

class AddStoryScreen extends StatelessWidget {
  final File image;
  final String avatarUrl;
  final String username;

  const AddStoryScreen({
    super.key,
    required this.image,
    required this.avatarUrl,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Xem trước Story'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final userId = FirebaseService().userId;
              final storagePath = 'stories/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
              final url = await FirebaseService().uploadImage(image: image, path: storagePath);

              await FirebaseService().createDocument(
                collection: 'stories',
                data: {
                  'userId': userId,
                  'imageUrl': url,
                  'createdAt': FieldValue.serverTimestamp(),
                },
              );

              Get.back();
              Get.snackbar('Thành công', 'Đã đăng Story!');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: Image.file(image, fit: BoxFit.cover, width: double.infinity)),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                const SizedBox(width: 8),
                Text(username, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
