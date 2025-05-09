// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:fluttergram/screens/create_post/edit_post_screen.dart';
//
// class MediaSelectionController extends GetxController {
//   final assetList = <AssetEntity>[].obs;
//   final selectedAssets = <AssetEntity>[].obs;
//   final isLoading = true.obs;
//   final mediaTypeFilter = 'all'.obs;
//   final currentAlbum = Rxn<AssetPathEntity>();
//   final albums = <AssetPathEntity>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _requestPermission();
//   }
//
//   Future<void> _requestPermission() async {
//     final result = await PhotoManager.requestPermissionExtend();
//     if (result.isAuth) {
//       await _loadAlbums();
//     } else {
//       Get.snackbar(
//         'Permission Denied',
//         'Please allow access to your media library',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   Future<void> _loadAlbums() async {
//     isLoading.value = true;
//
//     final albumList = await PhotoManager.getAssetPathList(
//       type: RequestType.all,
//       hasAll: true,
//     );
//
//     albums.value = albumList;
//
//     if (albums.isNotEmpty) {
//       currentAlbum.value = albums.first;
//       await _loadAssets();
//     }
//
//     isLoading.value = false;
//   }
//
//   Future<void> _loadAssets() async {
//     isLoading.value = true;
//
//     if (currentAlbum.value == null) {
//       isLoading.value = false;
//       return;
//     }
//
//     final assets = await currentAlbum.value!.getAssetListRange(
//       start: 0,
//       end: 100,
//     );
//
//     assetList.value = assets;
//     isLoading.value = false;
//
//     update(['assetGrid']);
//   }
//
//   void showAlbumSelection() {
//     Get.bottomSheet(
//       Container(
//         color: Colors.black,
//         child: ListView.builder(
//           itemCount: albums.length,
//           itemBuilder: (context, index) {
//             final album = albums[index];
//             return ListTile(
//               title: Text(
//                 album.name,
//                 style: const TextStyle(color: Colors.white),
//               ),
//               trailing: Obx(() =>
//               currentAlbum.value?.id == album.id
//                   ? const Icon(Icons.check, color: Colors.blue)
//                   : const SizedBox.shrink()
//               ),
//               onTap: () {
//                 currentAlbum.value = album;
//                 _loadAssets();
//                 Get.back();
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   void toggleMediaTypeFilter(String type) {
//     mediaTypeFilter.value = type;
//     update(['assetGrid']);
//   }
//
//   List<AssetEntity> get filteredAssets {
//     if (mediaTypeFilter.value == 'all') {
//       return assetList;
//     } else if (mediaTypeFilter.value == 'image') {
//       return assetList.where((asset) => asset.type == AssetType.image).toList();
//     } else if (mediaTypeFilter.value == 'video') {
//       return assetList.where((asset) => asset.type == AssetType.video).toList();
//     }
//     return assetList;
//   }
//
//   void toggleAssetSelection(AssetEntity asset) {
//     if (isAssetSelected(asset)) {
//       selectedAssets.remove(asset);
//     } else {
//       if (selectedAssets.length < 10) {
//         selectedAssets.add(asset);
//       } else {
//         Get.snackbar(
//           'Selection Limit',
//           'You can select up to 10 media items',
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       }
//     }
//
//     update(['nextButton', 'selectedPreview']);
//   }
//
//   bool isAssetSelected(AssetEntity asset) {
//     return selectedAssets.any((element) => element.id == asset.id);
//   }
//
//   int getSelectionIndex(AssetEntity asset) {
//     final index = selectedAssets.indexWhere((element) => element.id == asset.id);
//     return index;
//   }
//
//   void proceedToNextScreen() {
//     if (selectedAssets.isNotEmpty) {
//       Get.to(() => EditPostScreen(selectedAssets: selectedAssets.toList()));
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/screens/create_post/edit_post_screen.dart';

class MediaSelectionController extends GetxController {
  final assetList = <AssetEntity>[].obs;
  final selectedAssets = <AssetEntity>[].obs;
  final isLoading = true.obs;
  final currentAlbum = Rxn<AssetPathEntity>();
  final albums = <AssetPathEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      await _loadAlbums();
    } else {
      Get.snackbar(
        'Permission Denied',
        'Please allow access to your media library',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadAlbums() async {
    isLoading.value = true;

    final albumList = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    albums.value = albumList;

    if (albums.isNotEmpty) {
      currentAlbum.value = albums.first;
      await _loadAssets();
    }

    isLoading.value = false;
  }

  Future<void> _loadAssets() async {
    isLoading.value = true;

    if (currentAlbum.value == null) {
      isLoading.value = false;
      return;
    }

    final assets = await currentAlbum.value!.getAssetListRange(
      start: 0,
      end: 100,
    );

    assetList.value = assets.where((asset) => asset.type == AssetType.image).toList();
    isLoading.value = false;

    update(['assetGrid']);
  }

  void showAlbumSelection() {
    Get.bottomSheet(
      Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return ListTile(
              title: Text(
                album.name,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Obx(() =>
              currentAlbum.value?.id == album.id
                  ? const Icon(Icons.check, color: Colors.blue)
                  : const SizedBox.shrink()
              ),
              onTap: () {
                currentAlbum.value = album;
                _loadAssets();
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }

  // Direct access to image assets only
  List<AssetEntity> get imageAssets {
    return assetList;
  }

  void toggleAssetSelection(AssetEntity asset) {
    if (isAssetSelected(asset)) {
      selectedAssets.remove(asset);
    } else {
      if (selectedAssets.length < 10) {
        selectedAssets.add(asset);
      } else {
        Get.snackbar(
          'Selection Limit',
          'You can select up to 10 images',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    update(['nextButton', 'selectedPreview']);
  }

  bool isAssetSelected(AssetEntity asset) {
    return selectedAssets.any((element) => element.id == asset.id);
  }

  int getSelectionIndex(AssetEntity asset) {
    final index = selectedAssets.indexWhere((element) => element.id == asset.id);
    return index;
  }

  void proceedToNextScreen() {
    if (selectedAssets.isNotEmpty) {
      Get.to(() => EditPostScreen(selectedAssets: selectedAssets.toList()));
    }
  }
}