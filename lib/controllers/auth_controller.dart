import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';
import '../screens/auth/login_screen.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> signup({
    required String email,
    required String password,
    required String username,
    required String fullname,
    required String bio,
    required File? avatarFile,
    required BuildContext context,
  }) async {
    // Hiện vòng tròn loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Tạo tài khoản Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed.');
      final uid = user.uid;

      // Tải avatar lên Firebase Storage
      final avatarUrl = await _uploadAvatar(avatarFile, uid);

      // Chuẩn bị dữ liệu người dùng
      final userData = {
        'uid': uid,
        'email': email,
        'username': username,
        'fullname': fullname,
        'bio': bio,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now(),
        'post_count': 0,
        'follower_count': 0,
        'following_count': 0,
      };

      // Lưu dữ liệu vào Firestore
      await _firestore.collection('users').doc(uid).set(userData);

      // Ẩn vòng tròn loading
      Navigator.of(context).pop();

      // Hiển thị SnackBar thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản đã được tạo thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ),
      );

      // Chuyển hướng sau 1 giây
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => LoginScreen());
      });
    } on FirebaseAuthException catch (e) {
      // Ẩn vòng tròn loading nếu có lỗi
      Navigator.of(context).pop();

      String message;

      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      } else {
        message = 'Đăng ký thất bại.';
      }

      _showError(context, message);
    } catch (e, stackTrace) {
      // Ẩn vòng tròn loading nếu có lỗi bất ngờ
      Navigator.of(context).pop();

      debugPrint('Lỗi đăng ký: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showError(context, 'Vui lòng thử lại sau.');
    }
  }


  Future<String> _uploadAvatar(File? avatarFile, String uid) async {
    const defaultAvatarUrl =
        'https://firebasestorage.googleapis.com/v0/b/fluttergram-5077d.appspot.com/o/avatars%2Fdefaul%2Fdefaults.jpg?alt=media';

    if (avatarFile == null || !await avatarFile.exists()) return defaultAvatarUrl;

    try {
      final ref = _storage.ref().child('avatars/$uid/img_$uid.jpg');
      await ref.putFile(avatarFile);
      return await ref.getDownloadURL();
    } catch (e, stackTrace) {
      debugPrint('Avatar upload failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return defaultAvatarUrl;
    }
  }


  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    // Hiện vòng tròn loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ẩn loading trước khi chuyển trang
      Navigator.of(context).pop();

      Get.offAll(() => const MainLayout());
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Ẩn loading

      String message = '';
      if (e.code == 'invalid-email') {
        message = 'Địa chỉ email không hợp lệ.';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu.';
      } else {
        message = 'Đăng nhập thất bại. Vui lòng thử lại.';
      }

      _showError(context, message);
    } catch (e) {
      Navigator.of(context).pop(); // Ẩn loading nếu có lỗi bất ngờ

      _showError(context, 'Đã xảy ra lỗi.');
    }
  }

  Future<void> signout({required BuildContext context}) async {
    bool? confirmSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmSignOut != true) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await _auth.signOut();

    Navigator.of(context).pop();

    Get.offAll(() => const LoginScreen());
  }


  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
