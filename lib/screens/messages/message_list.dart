import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/messages_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

import 'message_item.dart';

class MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final String conversationId;
  final UserModel user;
  final Function(BuildContext, List<String>, int) openImageFullScreen;
  final Function(MessageModel) showReactionPicker;
  final Function(MessageModel) showMessageOptionsDialog;
  final Map<String, String> reactionEmojiMap;
  final String currentUserId;

  const MessageList({
    super.key,
    required this.scrollController,
    required this.conversationId,
    required this.user,
    required this.openImageFullScreen,
    required this.showReactionPicker,
    required this.showMessageOptionsDialog,
    required this.reactionEmojiMap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final MessagesController controller = Get.find<MessagesController>();

    return StreamBuilder<List<MessageModel>>(
      stream: controller.getMessagesStream(conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        final messages = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  SizedBox(height: 16),
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.avatar),
                    radius: 40,
                  ),
                  SizedBox(height: 8),
                  Text(user.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user.username, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  GetBuilder<MessagesController>(
                    id: 'user_post_count',
                    builder: (c) {
                      return Text(
                        'Tài khoản tích cực - ${c.userPostCount} bài viết',
                        style: TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                  SizedBox(height: 4),
                  Text('Bạn hãy nhắn tin với tài khoản Fluttergram này',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ElevatedButton(
                    onPressed: () {
                      Get.put(ProfileController()).navigateTo(user.uid);
                    },
                    child: Text('Xem trang cá nhân'),
                  ),
                  SizedBox(height: 16),
                ],
              );
            }
            final msg = messages[index - 1];
            final isSender = msg.senderUid == currentUserId;

            return GestureDetector(
              onDoubleTap: () => showMessageOptionsDialog(msg),
              onLongPress: () => showReactionPicker(msg),
              child: MessageItem(
                message: msg,
                isSender: isSender,
                reactionEmojiMap: reactionEmojiMap,
                openImageFullScreen: (images, index) => openImageFullScreen(context, images, index),
              ),
            );
          },
        );
      },
    );
  }
}
