import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'dart:typed_data';

class AssetThumbnail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            controller.toggleAssetSelection(asset);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              snapshot.data != null
                  ? Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              )
                  : Container(color: Colors.grey[800]),
              Positioned(
                top: 5,
                right: 5,
                child: Obx(() {
                  final isSelected = controller.isAssetSelected(asset);
                  final selectionIndex = controller.getSelectionIndex(asset);

                  return Container(
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
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}