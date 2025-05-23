import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'package:fluttergram/widgets/media_selection/media_grid.dart';
import 'package:fluttergram/widgets/media_selection/selected_assets_preview.dart';
import 'package:fluttergram/widgets/media_selection/album_selection_bottom_sheet.dart';

class MediaSelectionScreen extends StatelessWidget {
  const MediaSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaSelectionController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Chọn ảnh',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onPressed: () {
              AlbumSelectionBottomSheet.show(controller);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.assetList.isEmpty) {
                return const Center(
                  child: Text(
                    'No images found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return MediaGrid(controller: controller);
            }),
          ),
          Obx(() => controller.selectedAssets.isNotEmpty
              ? Container(
            height: 80,
            color: Colors.black,
            child: SelectedAssetsPreview(controller: controller),
          )
              : const SizedBox.shrink(),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                Obx(() => ElevatedButton(
                  onPressed: controller.selectedAssets.isNotEmpty
                      ? () => controller.proceedToNextScreen()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: Text(
                    controller.selectedAssets.isNotEmpty
                        ? 'Tiếp (${controller.selectedAssets.length})'
                        : 'Tiếp',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}