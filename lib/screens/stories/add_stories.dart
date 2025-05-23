import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/utils/snackbar_utils.dart';
import 'package:get/get.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class AddStoryScreen extends StatelessWidget {
  final File image;
  final UserModel user;

  const AddStoryScreen({
    super.key,
    required this.image,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Story'),
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
                  'username': user.username,
                  'userAvatar': user.avatar,
                },
              );

              Get.back();
              // Get.snackbar('Thành công', 'Đã đăng Story!');
              SnackbarUtils.showSuccess('Đã đăng Story!');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withAlpha((0.85 * 255).toInt()),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(user.avatar),
                            radius: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tin của bạn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withAlpha((0.85 * 255).toInt()),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}