import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/firebase_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessagesController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;
  String currentUserId = '';
  String currentUsername = '';
  int userPostCount = 0;
  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';
  List<File> selectedImages = [];
  bool isUploading = false;

  @override
  void onInit() {
    super.onInit();
    currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      _firestore.collection('users').doc(currentUserId).snapshots().listen((doc) {
        if (doc.exists) {
          currentUsername = doc.data()?['username'] ?? '';
          update();
        }
      });
    }
  }

  void updateSearchKeyword(String keyword) {
    searchKeyword = keyword.toLowerCase();
    update();
  }

  void addImages(List<File> images) {
    selectedImages.addAll(images);
    update(['selected_images']);
  }

  void removeImageAt(int index) {
    selectedImages.removeAt(index);
    update(['selected_images']);
  }

  void clearImages() {
    selectedImages.clear();
    update(['selected_images']);
  }

  void setUploading(bool uploading) {
    isUploading = uploading;
    update(['uploading_status']);
  }

  Future<void> countUserPosts(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      userPostCount = querySnapshot.docs.length;
      update(['user_post_count']);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi đếm bài viết: $e');
      }
      userPostCount = 0;
      update(['user_post_count']);
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations/$conversationId/messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  Future<void> sendMessage(
      String conversationId,
      MessageModel msg, {
        List<String> imageUrls = const [],
      }) async {
    final ref = _firestore.collection('conversations').doc(conversationId);

    final msgData = {
      'sender_uid': msg.senderUid,
      'sender_name': msg.senderName,
      'sender_avatar': msg.senderAvatar,
      'receiver_uid': msg.receiverUid,
      'message': msg.message,
      'createdAt': Timestamp.fromDate(msg.timestamp),
      'images': imageUrls,
    };

    final convData = {
      'members': [msg.senderUid, msg.receiverUid],
      'last_message': msg.message.isNotEmpty
          ? msg.message
          : (imageUrls.isNotEmpty ? '[Hình ảnh]' : ''),
      'last_sender_uid': msg.senderUid,
      'timestamp': Timestamp.fromDate(msg.timestamp),
    };

    if (!(await ref.get()).exists) await ref.set(convData);
    await ref.collection('messages').add(msgData);
    await ref.update(convData);
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final messageRef = _firestore.collection('conversations/$conversationId/messages').doc(messageId);
    final messageSnapshot = await messageRef.get();

    if (messageSnapshot.exists) {
      final data = messageSnapshot.data();
      final List<dynamic> imageUrls = data?['images'] ?? [];

      for (String url in imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi xóa ảnh: $e');
          }
        }
      }

      await messageRef.delete();
    }

    final lastMessageQuery = await _firestore
        .collection('conversations/$conversationId/messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (lastMessageQuery.docs.isNotEmpty) {
      final last = lastMessageQuery.docs.first.data();
      String lastMessageText = last['message'] ?? '';
      if (lastMessageText.trim().isEmpty) {
        lastMessageText = '[Hình ảnh]';
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'last_message': lastMessageText,
        'last_sender_uid': last['sender_uid'],
        'timestamp': last['createdAt'],
      });
    } else {
      await _firestore.collection('conversations').doc(conversationId).update({
        'last_message': '',
        'last_sender_uid': '',
        'timestamp': null,
      });
    }
  }

  Future<void> deleteConversation(String currentUserId, String otherUserId) async {
    final snapshot = await _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .get();

    for (var doc in snapshot.docs) {
      final members = List<String>.from(doc['members']);
      if (members.contains(otherUserId)) {
        final messages = await doc.reference.collection('messages').get();

        for (var msg in messages.docs) {
          final data = msg.data();
          final List<dynamic> imageUrls = data['images'] ?? [];

          for (String url in imageUrls) {
            try {
              final ref = _storage.refFromURL(url);
              await ref.delete();
            } catch (e) {
              if (kDebugMode) {
                print('Lỗi khi xóa ảnh: $e');
              }
            }
          }

          await msg.reference.delete();
        }

        await doc.reference.delete();
        break;
      }
    }
  }

  Stream<List<UserModel>> getRecentConversations(String currentUserId) {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> users = [];

      for (var doc in snapshot.docs) {
        final members = List<String>.from(doc['members']);
        final otherUserId = members.firstWhere((id) => id != currentUserId);

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['last_message'] = doc['last_message'];
          data['last_sender_uid'] = doc['last_sender_uid'];
          users.add(UserModel.fromMap(data));
        }
      }

      return users;
    });
  }

  Stream<List<UserModel>> getFilteredSuggestionsStream(String currentUserId) {
    final controller = StreamController<List<UserModel>>();
    final subscription = _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .listen((convSnap) async {
      final existingUserIds = <String>{};
      for (var doc in convSnap.docs) {
        final members = List<String>.from(doc['members']);
        for (var id in members) {
          if (id != currentUserId) existingUserIds.add(id);
        }
      }

      final userSnap = await _firestore.collection('users').get();

      final suggestions = userSnap.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) =>
      user.uid != currentUserId && !existingUserIds.contains(user.uid))
          .toList();

      controller.add(suggestions);
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  Stream<List<UserModel>> getRecentConversationsStream() {
    return getRecentConversations(currentUserId);
  }

  Stream<List<UserModel>> getSuggestionsStream() {
    return getFilteredSuggestionsStream(currentUserId);
  }

  Future<void> deleteConversationAndMessages(String otherUserId) async {
    if (userId != null) {
      await deleteConversation(userId!, otherUserId);
    }
  }

  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<List<String>> uploadImages({
    required List<File> images,
    required String path,
  }) async {
    List<String> imageUrls = [];

    for (var image in images) {
      final url = await _firebaseService.uploadImage(image: image, path: '$path/${DateTime.now().millisecondsSinceEpoch}');
      imageUrls.add(url);
    }

    return imageUrls;
  }

  bool _isEmojiVisible = false;
  bool get isEmojiVisible => _isEmojiVisible;

  void toggleEmojiKeyboard() {
    _isEmojiVisible = !_isEmojiVisible;
    update(['emoji']);
  }

  void hideEmojiKeyboard() {
    if (_isEmojiVisible) {
      _isEmojiVisible = false;
      update(['emoji']);
    }
  }

  Future<void> addOrRemoveReaction(String conversationId, String messageId, String reactionKey) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

    if (reactions[currentUserId] == reactionKey) {
      reactions.remove(currentUserId);
    } else {
      reactions[currentUserId] = reactionKey;
    }

    await messageRef.update({'reactions': reactions});
  }

  String formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
