import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'dart:typed_data';

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