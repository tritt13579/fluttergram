import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/profile/profile_screen.dart';


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
    final ref = _storage.ref().child('avatars/$uid/img_{$uid}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> saveProfile(BuildContext context) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The information has been updated!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }



}
