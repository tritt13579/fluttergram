import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../controllers/messages_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/message_model.dart';
import '../../models/user_chat_model.dart';
import '../../utils/snackbar_utils.dart';

class ChatScreen extends StatelessWidget {
  final UserChatModel user;
  ChatScreen({super.key, required this.user});

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesController _controller = Get.find<MessagesController>();
  final Map<String, String> _reactionEmojiMap = const {
    'like': '👍',
    'love': '❤️',
    'laugh': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  String getConversationId() {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return _controller.getConversationId(currentUser.uid, user.uid);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String conversationId, String currentUserId) async {
    final messageText = _messageController.text.trim();
    final selectedImages = _controller.selectedImages;
    if (messageText.isEmpty && selectedImages.isEmpty) return;

    _controller.setUploading(true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final senderName = userDoc.data()?['fullname'] ?? 'Bạn';
      final senderAvatar = userDoc.data()?['avatar_url'] ??
          'https://www.gravatar.com/avatar/placeholder?s=150&d=mp';

      final uploadedImageUrls = selectedImages.isNotEmpty
          ? await _controller.uploadImages(images: selectedImages, path: 'chat_images/$conversationId')
          : <String>[];

      final message = MessageModel(
        senderUid: currentUserId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        receiverUid: user.uid,
        message: messageText,
        timestamp: DateTime.now(),
        id: '',
        images: uploadedImageUrls,
      );

      await _controller.sendMessage(conversationId, message, imageUrls: uploadedImageUrls);
      _messageController.clear();
      _controller.clearImages();
    } catch (e) {
      SnackbarUtils.showError('Gửi tin nhắn thất bại: $e');
    } finally {
      _controller.setUploading(false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();

    if (files.isNotEmpty) {
      List<File> validImages = [];

      for (XFile file in files) {
        final imageFile = File(file.path);
        final fileSize = await imageFile.length();

        if (fileSize <= 3 * 1024 * 1024) {
          validImages.add(imageFile);
        } else {
          SnackbarUtils.showWarning('Ảnh "${file.name}" vượt quá 3MB và đã bị bỏ qua.');
        }
      }
      _controller.addImages(validImages);
    }
  }

  void _showReactionPicker(MessageModel msg, String conversationId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reactionEmojiMap.entries.map((entry) {
            return GestureDetector(
              onTap: () {
                _controller.addOrRemoveReaction(conversationId, msg.id, entry.key);
                Get.back();
              },
              child: Text(entry.value, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  void _showMessageOptionsDialog(MessageModel msg, String conversationId) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final isSender = msg.senderUid == currentUser.uid;
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSender)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Xóa'),
                onTap: () async {
                  Get.back();
                  // Hiện dialog xác nhận xóa
                  final confirmDelete = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Xác nhận'),
                      content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmDelete == true) {
                    if (msg.senderUid == currentUser.uid) {
                      await _controller.deleteMessage(conversationId, msg.id);
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Đóng'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  void _openImageFullScreen(List<String> images, int index) {
    Get.to(() => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(images[index]),
        ),
      ),
    ));
  }

  Widget _buildReactions(MessageModel msg) {
    if (msg.reactions == null || msg.reactions!.isEmpty) return const SizedBox.shrink();

    final reactionsCount = <String, int>{};
    for (var reaction in msg.reactions!.values) {
      reactionsCount[reaction] = (reactionsCount[reaction] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactionsCount.entries.map((entry) {
            final emoji = _reactionEmojiMap[entry.key] ?? '👍';
            final count = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  if (count > 1)
                    Text(' $count', style: const TextStyle(fontSize: 12, color: Colors.black)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return GetBuilder<MessagesController>(
      id: 'emoji',
      builder: (_) {
        if (!_controller.isEmojiVisible) return const SizedBox.shrink();
        return EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _messageController.text += emoji.emoji;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final String conversationId = getConversationId();

    _controller.countUserPosts(user.uid);
    _controller.hideEmojiKeyboard();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullname),
      ),
      body: Column(
        children: [
          // Phần list tin nhắn + avatar thông tin user
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _controller.getMessagesStream(conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                _scrollToBottom();
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
                            backgroundImage: NetworkImage(user.avatarUrl),
                            radius: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(user.fullname,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(user.username, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          GetBuilder<MessagesController>(
                            id: 'user_post_count',
                            builder: (c) {
                              return Text(
                                'Tài khoản tích cực - ${c.userPostCount} bài viết',
                                style: const TextStyle(color: Colors.grey),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text('Bạn hãy nhắn tin với tài khoản Fluttergram này',
                              style: TextStyle(color: Colors.grey, fontSize: 12)
                          ),
                          ElevatedButton(
                              onPressed: () {
                                Get.put(ProfileController()).navigateTo(user.uid);
                              },
                              child: const Text('Xem trang cá nhân')
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    final msg = messages[index - 1];
                    final isSender = msg.senderUid == currentUser.uid;

                    return GestureDetector(
                      onDoubleTap: () => _showMessageOptionsDialog(msg, conversationId),
                      onLongPress: () => _showReactionPicker(msg, conversationId),
                      child: Column(
                        crossAxisAlignment:
                        isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _controller.formatTimestamp(msg.timestamp),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ),
                          Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment:
                              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (msg.images.isNotEmpty)
                                  Stack(
                                    children: [
                                      msg.images.length == 1
                                          ? Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: GestureDetector(
                                          onTap: () => _openImageFullScreen(msg.images, 0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              msg.images[0],
                                              width: MediaQuery.of(context).size.width * 0.6,
                                              height: MediaQuery.of(context).size.width * 0.6,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )
                                          : Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.6,
                                          child: GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: msg.images.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 8,
                                              crossAxisSpacing: 8,
                                              childAspectRatio: 1,
                                            ),
                                            itemBuilder: (context, index) {
                                              return GestureDetector(
                                                onTap: () => _openImageFullScreen(msg.images, index),
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
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: _buildReactions(msg),
                                      ),
                                    ],
                                  ),
                                if (msg.message.isNotEmpty)
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: isSender ? Colors.redAccent : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.55,
                                          ),
                                          child: Text(
                                            msg.images.isNotEmpty ? 'Ảnh: ${msg.message}' : msg.message,
                                            style: TextStyle(
                                              color: isSender ? Colors.white : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: _buildReactions(msg),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
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
          _buildEmojiPicker(),

          GetBuilder<MessagesController>(
            id: 'selected_images',
            builder: (c) {
              if (c.selectedImages.isEmpty) return const SizedBox();
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(c.selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => c.removeImageAt(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),

          // Phần nhập text + button thêm ảnh + gửi tin nhắn
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo),
                  color: Colors.redAccent,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 2,
                    enabled: !_controller.isUploading,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      prefixIcon: GetBuilder<MessagesController>(
                        id: 'emoji',
                        builder: (_) {
                          return IconButton(
                            icon: Icon(
                              _controller.isEmojiVisible ? Icons.keyboard : Icons.emoji_emotions_outlined,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              _controller.toggleEmojiKeyboard();
                            },
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                    ),
                    onTap: () {
                      _controller.hideEmojiKeyboard();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GetBuilder<MessagesController>(
                  id: 'uploading_status',
                  builder: (c) {
                    return c.isUploading
                        ? const CircularProgressIndicator()
                        : IconButton(
                      onPressed: () => _sendMessage(conversationId, currentUser.uid),
                      icon: const Icon(Icons.send),
                      color: Colors.redAccent,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}