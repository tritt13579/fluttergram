import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../screens/profile/user_profile_screen.dart';
import 'bottom_nav_controller.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxList<PostModel> userPosts = <PostModel>[].obs;
  RxInt postCount = 0.obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      isLoading.value = true;
      final result = await UserModelSnapshot.getUserProfileAndPosts(uid);

      currentUser.value = result.user;
      userPosts.assignAll(result.posts);
      postCount.value = result.postCount;
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  void navigateToProfile(String userId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == currentUserId) {
      final navController = Get.find<BottomNavController>();
      navController.changeTab(4);
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
    } else {
      Get.to(() => UserProfileScreen(userId: userId));
    }
  }

  void navigateTo(String userId) {
    Get.to(() => UserProfileScreen(userId: userId));
  }
}