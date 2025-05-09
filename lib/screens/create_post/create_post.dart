import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergram/screens/create_post/media_selection_screen.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => const MediaSelectionScreen());
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}