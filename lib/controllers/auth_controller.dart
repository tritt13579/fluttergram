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
    try {
      // Create Firebase account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed.');
      final uid = user.uid;

      // Upload avatar to Firebase Storage
      final avatarUrl = await _uploadAvatarToFirebaseStorage(avatarFile, uid);

      // Prepare user data
      final userData = {
        'uid': uid,
        'email': email,
        'username': username,
        'fullname': fullname,
        'bio': bio,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now(),
      };

      // Save to Firestore
      await _firestore.collection('users').doc(uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => LoginScreen());
      });
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'That email is already in use.';
      } else {
        message = 'Registration failed: ${e.message}';
      }
      _showError(context, message);
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showError(context, 'An unexpected error occurred: $e');
    }
  }

  Future<String> _uploadAvatarToFirebaseStorage(File? avatarFile, String uid) async {
    const defaultAvatarUrl =
        'https://firebasestorage.googleapis.com/v0/b/fluttergram-5077d.appspot.com/o/avatars%2Fdefaul%2Fdefaults.jpg?alt=media';

    if (avatarFile == null || !await avatarFile.exists()) return defaultAvatarUrl;

    try {
      final ref = _storage.ref().child('avatars/$uid/img_$uid');
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
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.offAll(() => const MainLayout());
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else {
        message = 'Login failed. Please try again.';
      }
      _showError(context, message);
    } catch (e) {
      _showError(context, 'An unexpected error occurred.');
    }
  }

  Future<void> signout({required BuildContext context}) async {
    await _auth.signOut();
    Get.offAll(() => LoginScreen());
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
