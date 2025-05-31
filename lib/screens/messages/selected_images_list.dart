import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/messages_controller.dart';

class SelectedImagesList extends StatelessWidget {
  final MessagesController controller;

  const SelectedImagesList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MessagesController>(
      id: 'selected_images',
      builder: (c) {
        if (c.selectedImages.isEmpty) return SizedBox.shrink();

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: c.selectedImages.length,
            itemBuilder: (context, index) {
              final file = c.selectedImages[index];
              return Stack(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => c.removeImageAt(index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: Icon(Icons.close, size: 20, color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}
