import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  List<File> _selectedImages = [];

  bool _isEditing = false;
  String? _editingMessageId;

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
    final senderAvatar = userDoc.data()?['avatar_url'] ?? 'https://www.gravatar.com/avatar/placeholder?s=150&d=mp';

    if (_isEditing && _editingMessageId != null) {
      // Cập nhật tin nhắn đã tồn tại
      await FirebaseService().updateMessage(
        conversationId,
        _editingMessageId!,
        messageText,
      );

      setState(() {
        _isEditing = false;
        _editingMessageId = null;
      });
    } else {
      // Gửi tin nhắn mới
      final message = MessageModel(
        senderUid: currentUser.uid,
        senderName: senderName,
        senderAvatar: senderAvatar,
        receiverUid: widget.user.uid,
        message: messageText,
        timestamp: DateTime.now(),
        id: '',
      );

      await FirebaseService().sendMessage(conversationId, message);
    }

    final controller = Get.find<MessagesController>();
    _messageController.clear();
  }

  // Format timestamp for message
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${_weekdayToVietnamese(timestamp.weekday)}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }

  String _weekdayToVietnamese(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  // Select Image
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? files = await picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      setState(() {
        _selectedImages = files.map((f) => File(f.path)).toList();
      });
    }
  }
  void _showMessageOptionsDialog(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa tin nhắn'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUser = FirebaseAuth.instance.currentUser!;
                  final conversationId = getConversationId(currentUser.uid, widget.user.uid);

                  if (msg.senderUid == currentUser.uid) {
                    await FirebaseService().deleteMessage(conversationId, msg.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bạn chỉ có thể xóa tin nhắn của mình')),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa tin nhắn'),
                onTap: () {
                  Navigator.pop(context);
                  final currentUser = FirebaseAuth.instance.currentUser!;
                  if (msg.senderUid == currentUser.uid) {
                    setState(() {
                      _isEditing = true;
                      _editingMessageId = msg.id;
                      _messageController.text = msg.message;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                      // Cuộn đến tin nhắn đó nếu muốn
                      Future.delayed(Duration(milliseconds: 100), () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bạn chỉ có thể chỉnh sửa tin nhắn của mình')),
                    );
                  }
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.reply),
              //   title: Text('Trả lời tin nhắn'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // TODO: Xử lý trả lời tin nhắn nếu cần
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Hủy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final conversationId = getConversationId(currentUser.uid, widget.user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _editingMessageId = null;
                  _messageController.clear();
                });
              },
              tooltip: 'Hủy chỉnh sửa',
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: FirebaseService().getMessagesStream(conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Chưa có tin nhắn.'));
                }
                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length + 1, // thêm 1 dòng đầu avatar
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Phần avatar và thông tin người nhận
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(widget.user.avatar),
                              radius: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(widget.user.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(widget.user.username, style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('1 người theo dõi - 0 bài viết', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              'Bạn đã theo dõi tài khoản Instagram này từ năm 2025',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Divider(height: 24),
                          ],
                        ),
                      );
                    }

                    final msg = messages[index - 1];
                    final isSender = msg.senderUid == currentUser.uid;

                    if (_isEditing && msg.id == _editingMessageId) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: TextField(
                              controller: _messageController,
                              autofocus: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Chỉnh sửa tin nhắn...',
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onLongPress: () => _showMessageOptionsDialog(msg),
                      child: Column(
                        crossAxisAlignment: isSender
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
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
                          Align(
                            alignment:
                            isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  color: isSender ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Phần input gửi tin nhắn giữ nguyên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      scrollDirection: Axis.vertical,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final img = _selectedImages[index];
                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                img,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child:
                                Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                SizedBox(height: 5),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Colors.blueAccent),
                      onPressed: _pickImages,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhắn tin...',
                          filled: true,
                          fillColor: Colors.white12,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.blue,
                      ),
                      child: Icon(
                        _isEditing ? Icons.check : Icons.send,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}