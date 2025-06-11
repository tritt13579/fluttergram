import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
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
  RxBool isLoading = false.obs;

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

  Future<bool> saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    isLoading.value = true;
    update();

    try {
      String? newAvatarUrl = avatarUrl.value.isNotEmpty ? avatarUrl.value : null;
      if (avatarImage.value != null) {
        newAvatarUrl = await _uploadAvatar(avatarImage.value!, uid);
      }

      final map = await UserModelSnapshot.getMapUserModel();
      final oldUser = map[uid];
      if (oldUser == null) {
        isLoading.value = false;
        update();
        SnackbarUtils.showError("Không tìm thấy user!");
        return false;
      }

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

      isLoading.value = false;
      update();

      return true;

    } catch (e) {
      isLoading.value = false;
      update();
      SnackbarUtils.showError('Đã xảy ra lỗi: $e');
      return false;
    }
  }
}