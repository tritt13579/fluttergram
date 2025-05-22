import 'package:flutter/material.dart';
import 'package:fluttergram/controllers/media_selection_controller.dart';
import 'package:fluttergram/widgets/media_selection/asset_thumbnail.dart';

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