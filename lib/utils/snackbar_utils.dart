import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtils {
  static void showError(String message) {
    Get.snackbar(
      'Lỗi',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showWarning(String message) {
    Get.snackbar(
      'Thiếu nội dung',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showSuccess(String message) {
    Get.snackbar(
      'Thành công',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static void showPermissionDenied({String? message}) {
    Get.snackbar(
      'Quyền bị từ chối',
      message ?? 'Vui lòng cho phép truy cập vào thư viện phương tiện của bạn',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

}