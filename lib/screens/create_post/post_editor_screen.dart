import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../controllers/post_editor_controller.dart';

class PostEditorScreen extends StatelessWidget {
  final List<AssetEntity> selectedAssets;

  const PostEditorScreen({super.key, required this.selectedAssets});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostEditorController(selectedAssets: selectedAssets));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => controller.isLoading.value
            ? Container()
            : selectedAssets.length > 1
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${controller.currentPage.value + 1}/${selectedAssets.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        )
            : Container()),
        centerTitle: true,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: controller.mediaList.length,
              onPageChanged: (index) {
                controller.changePage(index);
              },
              itemBuilder: (context, index) {
                return controller.mediaList[index] != null
                    ? Container(
                  color: Colors.black,
                  child: Center(
                    child: Image.memory(
                      controller.mediaList[index]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
                    : const Center(
                  child: Text(
                    'Error loading media',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(() => _buildEditButton(
                  Icons.edit,
                  'Chỉnh sửa',
                  controller.currentPage.value,
                  controller,
                  context,
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 24,
              top: 8,
            ),
            child: ElevatedButton(
              onPressed: () => controller.proceedToFinalScreen(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tiếp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildEditButton(
      IconData icon,
      String label,
      int index,
      PostEditorController controller,
      BuildContext context,
      ) {
    return InkWell(
      onTap: () => controller.openImageEditor(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}