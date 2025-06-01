import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final EditProfileController controller = Get.put(EditProfileController());

  @override
  Widget build(BuildContext context) {
    controller.loadUserData();

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
          child: GetBuilder<EditProfileController>(
            builder: (_) => Column(
              children: [
                GestureDetector(
                  onTap: controller.pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: controller.avatarImage.value != null
                        ? FileImage(controller.avatarImage.value!)
                        : (controller.avatarUrl.value.isNotEmpty
                        ? NetworkImage(controller.avatarUrl.value)
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
                    controller.saveProfile();
                  },
                  child: const Text(
                    'Cập nhật',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}