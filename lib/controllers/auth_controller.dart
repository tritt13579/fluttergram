import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/utils/snackbar_utils.dart';
import 'package:get/get.dart';
import 'package:fluttergram/layouts/main_layout.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';

class ControllerAuth extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  var _mapUser = <String, UserModel>{};
  var isLoading = false;
  var isSignedIn = false;

  static ControllerAuth get() => Get.find();

  UserModel? get currentUser => _auth.currentUser?.uid != null ? _mapUser[_auth.currentUser!.uid] : null;
  bool get loading => isLoading;
  bool get signedIn => isSignedIn;

  @override
  Future<void> onReady() async {
    super.onReady();
    _checkAuthState();
  }

  void _checkAuthState() {
    _auth.authStateChanges().listen((User? user) {
      isSignedIn = user != null;
      update(['auth_state']);

      if (user != null) {
        _loadCurrentUser();
      } else {
        _mapUser.clear();
        update(['user_data']);
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    if (_auth.currentUser?.uid != null) {
      _mapUser = await UserModelSnapshot.getMapUserModel();
      update(['user_data']);
      UserModelSnapshot.listenDataChange(_mapUser, updateUI: () => update(['user_data']));
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String username,
    required String fullname,
    required String bio,
    required File? avatarFile,
  }) async {
    _setLoading(true);

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

      // Tạo UserModel
      final newUser = UserModel(
        uid: uid,
        email: email,
        username: username,
        fullname: fullname,
        bio: bio,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        postCount: 0,
      );

      // Lưu dữ liệu vào Firestore
      await UserModelSnapshot.insert(newUser);

      _setLoading(false);

      // Hiển thị SnackBar thông báo thành công
      SnackbarUtils.showSuccess("Tài khoản đã được tạo thành công! Vui lòng đăng nhập.");

      // Chuyển hướng sau 1 giây
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => LoginScreen());
      });
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
    } catch (e) {
      _setLoading(false);
      SnackbarUtils.showError("Vui lòng thử lại sau.");
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
    } catch (e) {
      if (kDebugMode) {
        print('Avatar upload failed: $e');
      }
      return defaultAvatarUrl;
    }
  }

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      Get.offAll(() => const MainLayout());
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
    } catch (e) {
      _setLoading(false);
      SnackbarUtils.showError("Đã xảy ra lỗi.");
    }
  }

  Future<void> signout() async {
    bool? confirmSignOut = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmSignOut != true) return;

    _setLoading(true);
    await _auth.signOut();
    _setLoading(false);
    Get.offAll(() => const LoginScreen());
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = '';

    switch (e.code) {
      case 'weak-password':
        message = 'Mật khẩu quá yếu.';
        break;
      case 'email-already-in-use':
        message = 'Email này đã được sử dụng.';
        break;
      case 'invalid-email':
        message = 'Email không hợp lệ.';
        break;
      case 'wrong-password':
        message = 'Sai mật khẩu.';
        break;
      default:
        message = 'Đăng nhập thất bại. Vui lòng thử lại.';
    }

    SnackbarUtils.showError(message);
  }

  void _setLoading(bool value) {
    isLoading = value;
    update(['loading_state']);
  }

  @override
  void onClose() {
    super.onClose();
    UserModelSnapshot.unsubscribeListenChange();
  }
}