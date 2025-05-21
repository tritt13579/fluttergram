import 'package:flutter/material.dart';
import 'dart:io';
import '../../controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = EditProfileController();
  File? pickedAvatar;

  @override
  void initState() {
    super.initState();
    controller.loadUserData(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.nameController.dispose();
    controller.userNameController.dispose();
    controller.bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Chỉnh sửa trang cá nhân'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  controller.pickImage((file) {
                    setState(() {
                      pickedAvatar = file;
                    });
                  });
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: pickedAvatar != null
                      ? FileImage(pickedAvatar!)
                      : (controller.avatarUrl != null
                      ? NetworkImage(controller.avatarUrl!)
                      : const AssetImage('assets/avatar.png'))
                  as ImageProvider,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller.nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.userNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.bioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tiểu sử',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.black,
                ),

                onPressed: () {
                  controller.saveProfile(context);
                },
                child: const Text(
                  'Cập nhật', // Màu đỏ đỏ 400
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
