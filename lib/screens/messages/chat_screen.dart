import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ services/firebase_service.dart';
import '../../controllers/messages_controller.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final UserModel user;
  const ChatScreen({super.key, required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    final conversationId = getConversationId(currentUser.uid, widget.user.uid);

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final senderName = userDoc.data()?['fullname'] ?? 'Bạn';
    final senderAvatar = userDoc.data()?['avatar_url'] ?? 'https://via.placeholder.com/150';

    final message = MessageModel(
      senderUid: currentUser.uid,
      senderName: senderName,
      senderAvatar: senderAvatar,
      receiverUid: widget.user.uid,
      message: messageText,
      timestamp: DateTime.now(),
    );

    FirebaseService().sendMessage(conversationId, message);
    final controller = Get.find<MessagesController>();
    await controller.fetchUserData();
    _messageController.clear();
  }

  String _formatTimestamp(DateTime timestamp) {
    final format = DateFormat('HH:mm dd/MM/yyyy');  // Định dạng thời gian
    return format.format(timestamp);
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final conversationId = getConversationId(currentUser.uid, widget.user.uid);

    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: FirebaseService().getMessagesStream(conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return Center(child: Text('Chưa có tin nhắn.'));

                final messages = snapshot.data!;

                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   if (_scrollController.hasClients) {
                //     _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                //   }
                // });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isSender = msg.senderUid == currentUser.uid;

                    return Column(
                      crossAxisAlignment: isSender
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Dòng thời gian tách riêng
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _formatTimestamp(msg.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ),

                        // Chat bubble
                        Align(
                          alignment: isSender
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSender
                                  ? Colors.blueAccent
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isSender
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.message,
                                  style: TextStyle(
                                    color: isSender
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  isSender ? 'Bạn' : msg.senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSender
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
