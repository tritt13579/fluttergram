import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';

class AlbumSelectionBottomSheet {
  static void show(MediaSelectionController controller) {
    Get.bottomSheet(
      Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: controller.albums.length,
          itemBuilder: (context, index) {
            final album = controller.albums[index];
            return ListTile(
              title: Text(
                album.name,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Obx(() => controller.currentAlbum.value?.id == album.id
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox.shrink()),
              onTap: () {
                controller.selectAlbum(album);
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }
}