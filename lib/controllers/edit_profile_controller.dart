import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergram/utils/snackbar_utils.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';

class EditProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final nameController = TextEditingController();
  final userNameController = TextEditingController();
  final bioController = TextEditingController();

  Rx<File?> avatarImage = Rx<File?>(null);
  RxString avatarUrl = "".obs;

  @override
  void onClose() {
    nameController.dispose();
    userNameController.dispose();
    bioController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final map = await UserModelSnapshot.getMapUserModel();
    final user = map[uid];
    if (user != null) {
      nameController.text = user.fullname;
      userNameController.text = user.username;
      bioController.text = user.bio;
      avatarUrl.value = user.avatarUrl;
      update();
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      avatarImage.value = File(picked.path);
      update();
    }
  }

  Future<String> _uploadAvatar(File image, String uid) async {
    final ref = _storage.ref().child('avatars/$uid/img_$uid.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> saveProfile(BuildContext context) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String? newAvatarUrl = avatarUrl.value.isNotEmpty ? avatarUrl.value : null;
      if (avatarImage.value != null) {
        newAvatarUrl = await _uploadAvatar(avatarImage.value!, uid);
      }

      final map = await UserModelSnapshot.getMapUserModel();
      final oldUser = map[uid];
      if (oldUser == null) return;

      final updatedUser = UserModel(
        uid: uid,
        email: oldUser.email,
        username: userNameController.text.trim(),
        fullname: nameController.text.trim(),
        bio: bioController.text.trim(),
        avatarUrl: newAvatarUrl ?? "",
        createdAt: oldUser.createdAt,
        postCount: oldUser.postCount,
      );
      await UserModelSnapshot.update(updatedUser);

      // Tắt loading
      Navigator.of(context).pop();
      // Hiển thị thông báo thành công
      SnackbarUtils.showSuccess("Cập nhật thông tin thành công!");

      Navigator.pop(context, true);
    } catch (e) {
      // Tắt loading nếu có lỗi
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}