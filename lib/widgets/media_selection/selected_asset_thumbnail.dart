import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'dart:typed_data';

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