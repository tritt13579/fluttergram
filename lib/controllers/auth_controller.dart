import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../screens/auth/login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      // Create Firebase account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed.');
      final uid = user.uid;

      // Generate custom user ID
      final userId = await _generateUniqueTextId();

      // Upload avatar to Supabase
      final avatarUrl = await _uploadAvatarToSupabase(avatarFile, userId);

      // Prepare user data
      final userData = {
        'id': userId,
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

  Future<String> _uploadAvatarToSupabase(File? avatarFile, String userId) async {
    const defaultAvatar =
        'https://phucklrkdeheqxxrjxxr.supabase.co/storage/v1/object/public/media/avatars/defaults/default.jpg';

    if (avatarFile == null || !await avatarFile.exists()) return defaultAvatar;

    try {
      final filePath = 'avatars/$userId/$userId.jpg';
      final response = await supabase.storage
          .from('media')
          .upload(filePath, avatarFile, fileOptions: const FileOptions(upsert: true));

      if (response.isNotEmpty) {
        return supabase.storage.from('media').getPublicUrl(filePath);
      } else {
        debugPrint('Upload returned empty response.');
        return defaultAvatar;
      }
    } catch (e, stackTrace) {
      debugPrint('Avatar upload failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return defaultAvatar;
    }
  }


  Future<String> _generateUniqueTextId() async {
    final snapshot = await _firestore.collection('users').get();
    final existingIds = snapshot.docs.map((doc) => doc['id'] as String).toSet();

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
