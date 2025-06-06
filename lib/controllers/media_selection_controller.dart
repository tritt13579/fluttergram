import 'package:fluttergram/utils/snackbar_utils.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluttergram/screens/create_post/post_editor_screen.dart';

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
      SnackbarUtils.showPermissionDenied(message: "Please allow access to your media library");
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

  void selectAlbum(AssetPathEntity album) {
    currentAlbum.value = album;
    _loadAssets();
  }

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
      Get.to(() => PostEditorScreen(selectedAssets: selectedAssets.toList()));
    }
  }
}