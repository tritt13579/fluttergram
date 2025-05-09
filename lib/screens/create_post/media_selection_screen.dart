import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import '../../main.dart';

class MediaSelectionScreen extends StatefulWidget {
  const MediaSelectionScreen({super.key});

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  late MediaSelectionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MediaSelectionController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.offAll(MainLayout()),
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
              controller.showAlbumSelection();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GetBuilder<MediaSelectionController>(
              id: 'assetGrid',
              builder: (_) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.assetList.isEmpty) {
                  return const Center(child: Text('No images found', style: TextStyle(color: Colors.white)));
                }

                return MediaGrid(controller: controller);
              },
            ),
          ),
          GetBuilder<MediaSelectionController>(
            id: 'selectedPreview',
            builder: (_) => controller.selectedAssets.isNotEmpty
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
                GetBuilder<MediaSelectionController>(
                  id: 'nextButton',
                  builder: (_) => ElevatedButton(
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MediaGrid extends StatelessWidget {
  final MediaSelectionController controller;

  const MediaGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: controller.imageAssets.length,
      itemBuilder: (context, index) {
        final asset = controller.imageAssets[index];
        return AssetThumbnail(
          asset: asset,
          controller: controller,
          index: index,
        );
      },
    );
  }
}

class AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final MediaSelectionController controller;
  final int index;

  const AssetThumbnail({
    super.key,
    required this.asset,
    required this.controller,
    required this.index,
  });

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  Uint8List? thumbnailData;
  bool isSelected = false;
  int selectionIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _updateSelectionState();

    ever(widget.controller.selectedAssets, (_) {
      if (mounted) {
        _updateSelectionState();
      }
    });
  }

  void _updateSelectionState() {
    final newIsSelected = widget.controller.isAssetSelected(widget.asset);
    final newSelectionIndex = widget.controller.getSelectionIndex(widget.asset);

    if (newIsSelected != isSelected || newSelectionIndex != selectionIndex) {
      setState(() {
        isSelected = newIsSelected;
        selectionIndex = newSelectionIndex;
      });
    }
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailData;
    if (mounted) {
      setState(() {
        thumbnailData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.controller.toggleAssetSelection(widget.asset);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbnailData != null
              ? Image.memory(
            thumbnailData!,
            fit: BoxFit.cover,
          )
              : Container(color: Colors.grey[800]),

          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.black.withAlpha((0.5 * 255).toInt()),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.white,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Text(
                  '${selectionIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedAssetsPreview extends StatelessWidget {
  final MediaSelectionController controller;

  const SelectedAssetsPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: controller.selectedAssets.length,
      itemBuilder: (context, index) {
        final asset = controller.selectedAssets[index];
        return SelectedAssetThumbnail(
          asset: asset,
          controller: controller,
        );
      },
    );
  }
}

class SelectedAssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final MediaSelectionController controller;

  const SelectedAssetThumbnail({
    super.key,
    required this.asset,
    required this.controller,
  });

  @override
  State<SelectedAssetThumbnail> createState() => _SelectedAssetThumbnailState();
}

class _SelectedAssetThumbnailState extends State<SelectedAssetThumbnail> {
  Uint8List? thumbnailData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailData;
    if (mounted) {
      setState(() {
        thumbnailData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnailData != null
                ? Image.memory(
              thumbnailData!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
                : Container(
              width: 60,
              height: 60,
              color: Colors.grey[800],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => widget.controller.toggleAssetSelection(widget.asset),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.5 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}