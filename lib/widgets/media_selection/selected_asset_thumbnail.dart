import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'dart:typed_data';

class SelectedAssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final MediaSelectionController controller;

  const SelectedAssetThumbnail({
    super.key,
    required this.asset,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailData,
        builder: (context, snapshot) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: snapshot.data != null
                    ? Image.memory(
                  snapshot.data!,
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
                  onTap: () => controller.toggleAssetSelection(asset),
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
          );
        },
      ),
    );
  }
}