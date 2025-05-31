import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/messages_controller.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

import 'message_list.dart';
import 'selected_images_list.dart';
import 'reaction_picker.dart';

import 'package:pro_image_editor/plugins/emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../utils/snackbar_utils.dart';

class ChatScreen extends StatefulWidget {
  final UserModel user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesController _controller = Get.find<MessagesController>();
  late String _conversationId;
  final currentUser = FirebaseAuth.instance.currentUser!;
  final Map<String, String> _reactionEmojiMap = {
    'like': '👍',
    'love': '❤️',
    'laugh': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  @override
  void initState() {
    super.initState();
    _conversationId = _controller.getConversationId(currentUser.uid, widget.user.uid);
    _controller.countUserPosts(widget.user.uid);
    _controller.hideEmojiKeyboard();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _controller.clearImages();
    _controller.hideEmojiKeyboard();
    super.dispose();
  }
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final selectedImages = _controller.selectedImages;
    if (messageText.isEmpty && selectedImages.isEmpty) return;

    _controller.setUploading(true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final senderName = userDoc.data()?['fullname'] ?? 'Bạn';
      final senderAvatar = userDoc.data()?['avatar_url'] ??
          'https://www.gravatar.com/avatar/placeholder?s=150&d=mp';

      final uploadedImageUrls = selectedImages.isNotEmpty
          ? await _controller.uploadImages(images: selectedImages, path: 'chat_images/$_conversationId')
          : <String>[];

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
      _messageController.clear();
      _controller.clearImages();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError('Gửi tin nhắn thất bại!');
      }
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
          SnackbarUtils.showError('Ảnh "${file.name}" vượt quá 3MB và đã bị bỏ qua.');
        }
      }
      _controller.addImages(validImages);
    }
  }

  void _openImageFullScreen(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Center(
            child: InteractiveViewer(child: Image.network(images[index])),
          ),
        ),
      ),
    );
  }

  void _showMessageOptionsDialog(MessageModel msg) {
    final isSender = msg.senderUid == currentUser.uid;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSender)
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Xóa'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Xác nhận'),
                      content: Text('Bạn có chắc muốn xóa tin nhắn này?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hủy')),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Xóa', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirmDelete == true) {
                    final conversationId = _controller.getConversationId(currentUser.uid, widget.user.uid);
                    if (msg.senderUid == currentUser.uid) {
                      await _controller.deleteMessage(conversationId, msg.id);
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

  void _showReactionPicker(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ReactionPicker(
        reactionEmojiMap: _reactionEmojiMap,
        onReactionSelected: (key) {
          _controller.addOrRemoveReaction(_conversationId, msg.id, key);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return GetBuilder<MessagesController>(
      id: 'emoji',
      builder: (_) {
        if (!_controller.isEmojiVisible) return SizedBox.shrink();
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: Column(
        children: [
          Expanded(
            child: MessageList(
              scrollController: _scrollController,
              conversationId: _conversationId,
              user: widget.user,
              openImageFullScreen: _openImageFullScreen,
              showMessageOptionsDialog: _showMessageOptionsDialog,
              showReactionPicker: _showReactionPicker,
              reactionEmojiMap: _reactionEmojiMap,
              currentUserId: currentUser.uid,
            ),
          ),
          _buildEmojiPicker(),
          SelectedImagesList(controller: _controller),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImages,
                  icon: Icon(Icons.photo),
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
                              _controller.isEmojiVisible
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions_outlined,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _controller.toggleEmojiKeyboard(),
                          );
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                    ),
                    onTap: () => _controller.hideEmojiKeyboard(),
                  ),
                ),
                SizedBox(width: 8),
                GetBuilder<MessagesController>(
                  id: 'uploading_status',
                  builder: (_) {
                    return _controller.isUploading
                        ? CircularProgressIndicator()
                        : IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send),
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
