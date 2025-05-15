import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/messages_controller.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MessagesController>(
      init: Get.put(MessagesController()),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              controller.currentUsername.isNotEmpty
                  ? controller.currentUsername
                  : 'Tài khoản',
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_square),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Recent Messages Stream
                StreamBuilder<List<UserModel>>(
                  stream: controller.getRecentConversationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Các đoạn tin nhắn sẽ hiển thị ở đây sau khi bạn gửi hoặc nhận.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final recentMessages = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tin nhắn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ...recentMessages.map((user) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.avatar),
                                radius: 24,
                              ),
                              title: Text(user.name),
                              subtitle: Text(
                                (user.lastMessage != null && user.lastMessage!.trim().isNotEmpty)
                                    ? (user.lastSenderUid == controller.currentUserId
                                    ? 'Bạn: ${user.lastMessage}'
                                    : '${user.name}: ${user.lastMessage}')
                                    : 'Nhấn vào để chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(user: user),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await controller.deleteConversationAndMessages(user.uid);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
                // Suggested Users Stream
                StreamBuilder<List<UserModel>>(
                  stream: controller.getSuggestionsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Không có gợi ý nào.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final recommended = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gợi ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ...recommended.map((user) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.avatar),
                                radius: 24,
                              ),
                              title: Text(user.name),
                              subtitle: Text(user.username),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(user: user),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
