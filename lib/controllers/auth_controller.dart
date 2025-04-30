import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../screens/auth/login_screen.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final supabase = Supabase.instance.client;

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
      // Đăng ký tài khoản Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Tạo ID
      final userId = await _generateUniqueTextId();


      //loi cho nay
      String? avatarUrl;

      if (avatarFile != null && await avatarFile.exists()) {
        try {
          final filePath = 'avatars/$userId/$userId.jpg';

          final uploadResponse = await supabase.storage
              .from('media')
              .upload(
            filePath,
            avatarFile,
            fileOptions: const FileOptions(upsert: true),
          );

          if (uploadResponse != null && uploadResponse.isNotEmpty) {
            avatarUrl = supabase.storage
                .from('media')
                .getPublicUrl(filePath);
          } else {
            debugPrint('Upload response empty — possibly failed silently.');
          }
        } catch (e, stackTrace) {
          debugPrint('Upload avatar failed: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      final response = await supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': username,
        'fullname': fullname,
        'bio': bio,
        'avatar_url': avatarUrl ?? 'https://phucklrkdeheqxxrjxxr.supabase.co/storage/v1/object/public/avatars/media/avatars/defaults/defaults.jpg',
        'created_at': DateTime.now().toIso8601String(),
      });

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
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      } else {
        message = 'Registration failed. Please try again.';
      }
      _showError(context, message);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showError(context, 'An unexpected error occurred: $e');
    }
  }

  Future<String> _generateUniqueTextId() async {
    final List<dynamic> data = await supabase.from('users').select('id');
    final existingIds = data.map((e) => e['id'] as String).toSet();

    String newId;
    do {
      newId = (Random().nextInt(900000) + 100000).toString();
    } while (existingIds.contains(newId));

    return newId;
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
