import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final MessagesController _controller = Get.find<MessagesController>();
  List<File> _selectedImages = [];
  bool _isEditing = false;
  String? _editingMessageId;
  late String _conversationId;

  final currentUser = FirebaseAuth.instance.currentUser!;

  bool _isUploading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _selectedImages.isEmpty) return;

    if (_isUploading) return;  // Nếu đang gửi ảnh thì không cho gửi thêm

    if (_selectedImages.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final senderName = userDoc.data()?['fullname'] ?? 'Bạn';
      final senderAvatar = userDoc.data()?['avatar_url'] ?? 'https://www.gravatar.com/avatar/placeholder?s=150&d=mp';

      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await _controller.uploadImages(images: _selectedImages, path: 'chat_images/$_conversationId');
      }

      if (_isEditing && _editingMessageId != null) {
        final oldMessage = await _controller.getMessageById(_conversationId, _editingMessageId!);
        final keepOldImages = oldMessage.images.isNotEmpty;

        await _controller.updateMessage(
          _conversationId,
          _editingMessageId!,
          messageText,
          images: keepOldImages ? oldMessage.images : uploadedImageUrls,
        );
        setState(() {
          _isEditing = false;
          _editingMessageId = null;
        });
      } else {
        final message = MessageModel(
          senderUid: currentUser.uid,
          senderName: senderName,
          senderAvatar: senderAvatar,
          receiverUid: widget.user.uid,
          message: messageText,
          timestamp: DateTime.now(),
          id: '',
          images: uploadedImageUrls,
        );

        await _controller.sendMessage(_conversationId, message, imageUrls: uploadedImageUrls);
      }

      _messageController.clear();

      if (_selectedImages.isNotEmpty) {
        setState(() {
          _selectedImages.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi tin nhắn thất bại: $e'), backgroundColor: Colors.red),
      );
    } finally {
        _isUploading = false;
    }
  }


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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? files = await picker.pickMultiImage();

    if (files != null && files.isNotEmpty) {
      List<File> validImages = [];

      for (XFile file in files) {
        final imageFile = File(file.path);
        final fileSize = await imageFile.length();

        if (fileSize <= 3 * 1024 * 1024) {
          validImages.add(imageFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ảnh "${file.name}" vượt quá 3MB và đã bị bỏ qua.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() {
        _selectedImages = validImages;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser!;
    _conversationId = _controller.getConversationId(currentUser.uid, widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
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
              stream: _controller.getMessagesStream(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          CircleAvatar(
                            backgroundImage: NetworkImage(widget.user.avatar),
                            radius: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(widget.user.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(widget.user.username, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('1 người theo dõi - 0 bài viết', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Bạn đã theo dõi tài khoản Instagram này từ năm 2025',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 16),
                        ],
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
                        crossAxisAlignment:
                        isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _formatTimestamp(msg.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ),
                          Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment:
                              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (msg.images.isNotEmpty) ...[
                                  if (msg.images.length == 1)
                                    GestureDetector(
                                      onTap: () => _openImageFullScreen(context, msg.images, 0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          msg.images[0],
                                          width: MediaQuery.of(context).size.width * 0.6,
                                          height: MediaQuery.of(context).size.width * 0.6,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: msg.images.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 1,
                                        ),
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () => _openImageFullScreen(context, msg.images, index),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                msg.images[index],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                ],
                                if (msg.message.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg.images.isNotEmpty
                                          ? 'Tin nhắn ảnh: ${msg.message}'
                                          : msg.message,
                                      style: TextStyle(
                                        color: isSender ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 8),
                              ],
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
          if (_isUploading)
            LinearProgressIndicator(minHeight: 4),
          // input giữ nguyên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isUploading ? null : _pickImages,
                      icon: Icon(Icons.photo),
                      color: Colors.blue,
                      tooltip: 'Chọn ảnh',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isUploading,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                        backgroundColor: Colors.blue,
                      ),
                      child: _isUploading
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        _isEditing ? Icons.check : Icons.send,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptionsDialog(MessageModel msg) {
    final isSender = msg.senderUid == currentUser.uid;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSender)
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isEditing = true;
                    _editingMessageId = msg.id;
                    _messageController.text = msg.message;
                  });
                },
              ),
            if (isSender)
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Xóa'),
                onTap: () async {
                  Navigator.pop(context);
                  // Hiện dialog xác nhận xóa
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Xác nhận'),
                        content: Text('Bạn có chắc muốn xóa tin nhắn này?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Xóa', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    final currentUser = FirebaseAuth.instance.currentUser!;
                    final conversationId = _controller.getConversationId(currentUser.uid, widget.user.uid);

                    if (msg.senderUid == currentUser.uid) {
                      await _controller.deleteMessage(conversationId, msg.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bạn chỉ có thể xóa tin nhắn của mình')),
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('Đóng'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  void _openImageFullScreen(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(images[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
