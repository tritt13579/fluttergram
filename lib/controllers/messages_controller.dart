import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../ services/firebase_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessagesController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;
  String get currentUserId => userId ?? '';
  String get currentUsername => currentUser?.displayName ?? '';

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
      'images': imageUrls, // thêm dòng này
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
          print('Lỗi khi xóa ảnh: $e');
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
              print('Lỗi khi xóa ảnh: $e');
            }
          }

          await msg.reference.delete();
        }

        await doc.reference.delete();
        break;
      }
    }
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map(
            (snapshot) => snapshot.docs.map((e) => UserModel.fromMap(e.data())).toList());
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

  Stream<List<String>> getConversationUserIdsStream(String currentUserId) {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final userIds = <String>{};
      for (var doc in snapshot.docs) {
        final members = List<String>.from(doc['members']);
        for (var id in members) {
          if (id != currentUserId) {
            userIds.add(id);
          }
        }
      }
      return userIds.toList();
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

  Future<String> uploadImage({required File image, required String path}) {
    return _firebaseService.uploadImage(image: image, path: path);
  }

  Future<String> updateImage({required File image, required String path}) {
    return _firebaseService.updateImage(image: image, path: path);
  }

  Future<void> deleteImage({required String path}) {
    return _firebaseService.deleteImage(path: path);
  }


  // đổi tên hàm cho dễ nhớ
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

  Future<void> updateMessage(
      String conversationId,
      String messageId,
      String newContent, {
        List<String>? images,
      }) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final docRef = messagesRef.doc(messageId);

    Map<String, dynamic> updateData = {
      'message': newContent,
      'editedTimestamp': DateTime.now(),
    };

    if (images != null) {
      updateData['images'] = images;
    }

    await docRef.update(updateData);

    final lastMessageQuery = await messagesRef
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (lastMessageQuery.docs.isNotEmpty &&
        lastMessageQuery.docs.first.id == messageId) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'last_message': newContent,
        'last_sender_uid': lastMessageQuery.docs.first['sender_uid'],
        'timestamp': Timestamp.now(),
      });
    }
  }
  Future<MessageModel> getMessageById(String conversationId, String messageId) async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!doc.exists) throw Exception('Message not found');

    return MessageModel.fromMap(doc.data()!..['id'] = doc.id);
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
}
