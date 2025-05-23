import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../screens/profile/user_profile_screen.dart';
import 'bottom_nav_controller.dart';

class ProfileController extends GetxController {
  void navigateToProfile(String userId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == currentUserId) {
      final navController = Get.find<BottomNavController>();
      navController.changeTab(4);
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
    }  else {
      Get.to(() => UserProfileScreen(userId: userId));
    }
  }

  void navigateTo(String userId) {
      Get.to(() => UserProfileScreen(userId: userId));
  }
}