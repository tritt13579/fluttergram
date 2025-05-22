import 'package:flutter/material.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'package:fluttergram/widgets/media_selection/selected_asset_thumbnail.dart';

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