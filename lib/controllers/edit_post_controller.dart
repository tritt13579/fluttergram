import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:typed_data';
import '../screens/create_post/final_post_screen.dart';

class EditPostController extends GetxController {
  final List<AssetEntity> selectedAssets;

  final RxList<Uint8List?> mediaList = <Uint8List?>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt currentPage = 0.obs;
  final PageController pageController = PageController();

  EditPostController({required this.selectedAssets});

  @override
  void onInit() {
    super.onInit();
    loadMediaData();
  }

  Future<void> loadMediaData() async {
    isLoading.value = true;

    List<Uint8List?> tempList = [];
    for (var asset in selectedAssets) {
      final data = await asset.originBytes;
      tempList.add(data);
    }

    mediaList.value = tempList;
    isLoading.value = false;
  }

  void changePage(int index) {
    currentPage.value = index;
  }

  Future<void> openImageEditor(BuildContext context, int index) async {
    if (mediaList[index] == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          mediaList[index]!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              mediaList[index] = editedBytes;
              mediaList.refresh();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void proceedToFinalScreen() {
    if (mediaList.isNotEmpty) {
      Get.to(() => FinalPostScreen(mediaList: mediaList.toList()));
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}