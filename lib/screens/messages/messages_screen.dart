import 'package:flutter/material.dart';
import 'package:fluttergram/models/user_chat_model.dart';
import 'package:get/get.dart';
import '../../controllers/messages_controller.dart';
import '../profile/edit_profile_screen.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MessagesController>(
      init: Get.put(MessagesController()),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: Text(controller.currentUsername.isNotEmpty
              ? controller.currentUsername
              : 'Tài khoản'
          ),
          actions: [
            IconButton(icon: const Icon(Icons.edit_square), onPressed: () {Get.to(() => EditProfileScreen());}),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchBar(controller),
              _buildRecentMessages(controller, context),
              _buildSuggestions(controller, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(MessagesController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: controller.searchController,
        onChanged: (value) => controller.updateSearchKeyword(value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey.shade800,
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMessages(MessagesController controller, BuildContext context) {
    return StreamBuilder<List<UserChatModel>>(
      stream: controller.getRecentConversationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildEmptyMessage('Các đoạn tin nhắn sẽ hiển thị ở đây sau khi bạn gửi hoặc nhận tin nhắn.');
        }

        final filteredData = controller.searchKeyword.isEmpty
            ? data
            : data.where((user) => user.username.toLowerCase().contains(controller.searchKeyword)).toList();

        if (filteredData.isEmpty) {
          return _buildEmptyMessage('Không tìm thấy tin nhắn phù hợp.');
        }

        return _buildUserSection(
          title: 'Tin nhắn',
          users: filteredData,
          controller: controller,
          context: context,
          showMenu: true,
        );
      },
    );
  }

  Widget _buildSuggestions(MessagesController controller, BuildContext context) {
    return StreamBuilder<List<UserChatModel>>(
      stream: controller.getSuggestionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const SizedBox.shrink();
        }

        final filteredSuggestions = controller.searchKeyword.isEmpty
            ? data
            : data.where((user) => user.username.toLowerCase().contains(controller.searchKeyword)).toList();

        if (filteredSuggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildUserSection(
          title: 'Gợi ý',
          users: filteredSuggestions,
          controller: controller,
          context: context,
          showMenu: false,
        );
      },
    );
  }


  Widget _buildEmptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildUserSection({
    required String title,
    required List<UserChatModel> users,
    required BuildContext context,
    MessagesController? controller,
    bool showMenu = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề nhóm người dùng
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // Danh sách người dùng
          for (int i = 0; i < users.length; i++)
            _buildUserTile(
              user: users[i],
              context: context,
              controller: controller,
              showMenu: showMenu,
            ),
        ],
      ),
    );
  }

// Hàm tạo ListTile cho từng user
  Widget _buildUserTile({
    required UserChatModel user,
    required BuildContext context,
    MessagesController? controller,
    required bool showMenu,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.avatarUrl),
        radius: 24,
      ),
      title: Text(user.fullname),
      subtitle: Text(
        showMenu
            ? _getLastMessageText(user, controller)
            : user.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(user: user)),
        );
      },
      trailing: showMenu
          ? _buildPopupMenu(context, user, controller)
          : null,
    );
  }

  String _getLastMessageText(UserChatModel user, MessagesController? controller) {
    if (user.lastMessage != null && user.lastMessage!.trim().isNotEmpty) {
      if (user.lastSenderUid == controller?.currentUserId) {
        return 'Bạn: ${user.lastMessage}';
      } else {
        return '${user.fullname}: ${user.lastMessage}';
      }
    }
    return 'Nhấn vào để chat';
  }

  Widget _buildPopupMenu(BuildContext context, UserChatModel user, MessagesController? controller) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'delete') {
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Bạn có chắc chắn muốn xóa kênh tin nhắn này? (các tin nhắn sẽ bị xóa toàn bộ)'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xóa'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await controller?.deleteConversationAndMessages(user.uid);
            Get.snackbar('Thông báo', 'Đã xóa kênh tin nhắn.');
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'delete', child: Text('Xóa tin nhắn')),
        PopupMenuItem(value: 'close', child: Text('Đóng')),
      ],
    );
  }
}
