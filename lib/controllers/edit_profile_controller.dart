import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final nameController = TextEditingController();
  final userNameController = TextEditingController();
  final bioController = TextEditingController();

  File? avatarImage;
  String? avatarUrl;

  Future<void> loadUserData(VoidCallback onLoaded) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      nameController.text = data['fullname'] ?? '';
      userNameController.text = data['username'] ?? '';
      bioController.text = data['bio'] ?? '';
      avatarUrl = data['avatar_url'];
      onLoaded();
    }
  }

  Future<void> pickImage(Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      avatarImage = File(picked.path);
      onPicked(avatarImage!);
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
      String? newAvatarUrl = avatarUrl;
      if (avatarImage != null) {
        newAvatarUrl = await _uploadAvatar(avatarImage!, uid);
      }

      await _firestore.collection('users').doc(uid).update({
        'fullname': nameController.text.trim(),
        'username': userNameController.text.trim(),
        'bio': bioController.text.trim(),
        'avatar_url': newAvatarUrl,
      });

      // Tắt loading
      Navigator.of(context).pop();
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );

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
