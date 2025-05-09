import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class AppPermissions {
  static Future<bool> requestMediaPermissions() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();

    if (result.isAuth) {
      return true;
    } else if (result.hasAccess) {
      return true;
    } else {
      Get.snackbar(
        'Permission Required',
        'Please allow access to your photos and videos to use this feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            PhotoManager.openSetting();
          },
          child: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return false;
    }
  }
}