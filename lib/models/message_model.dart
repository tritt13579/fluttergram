import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../services/firebase_service.dart';

class MessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderAvatar;
  final String receiverUid;
  final String message;
  final DateTime timestamp;
  final List<String> images;
  final Map<String, String>? reactions;

  const MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverUid,
    required this.message,
    required this.timestamp,
    required this.images,
    this.reactions,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MessageModel(
      id: id ?? '',
      senderUid: map['sender_uid'] ?? '',
      senderName: map['sender_name'] ?? '',
      senderAvatar: map['sender_avatar'] ?? '',
      receiverUid: map['receiver_uid'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['createdAt'] as Timestamp).toDate(),
      images: List<String>.from(map['images'] ?? []),
      reactions: map['reactions'] != null
          ? Map<String, String>.from(map['reactions'])
          : null,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'receiver_uid': receiverUid,
      'message': message,
      'createdAt': Timestamp.fromDate(timestamp),
      'images': images,
      'reactions': reactions ?? {},
    };
  }
}

class MessageModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();

  static Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firebaseService.firestore
        .collection('conversations/$conversationId/messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  static Future<void> sendMessage(
      String conversationId,
      MessageModel msg, {
        List<String> imageUrls = const [],
      }) async {
    final ref = _firebaseService.firestore.collection('conversations').doc(conversationId);

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

  static Future<void> deleteMessage(String conversationId, String messageId) async {
    final firestore = _firebaseService.firestore;
    final storage = _firebaseService.storage;
    final messageRef = firestore.collection('conversations/$conversationId/messages').doc(messageId);
    final messageSnapshot = await messageRef.get();

    if (messageSnapshot.exists) {
      final data = messageSnapshot.data();
      final List<dynamic> imageUrls = data?['images'] ?? [];

      for (String url in imageUrls) {
        try {
          final ref = storage.refFromURL(url);
          await ref.delete();
        } catch (_) {}
      }

      await messageRef.delete();
    }

    final lastMessageQuery = await firestore
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

      await firestore.collection('conversations').doc(conversationId).update({
        'last_message': lastMessageText,
        'last_sender_uid': last['sender_uid'],
        'timestamp': last['createdAt'],
      });
    } else {
      await firestore.collection('conversations').doc(conversationId).update({
        'last_message': '',
        'last_sender_uid': '',
        'timestamp': null,
      });
    }
  }

  static Future<void> deleteConversation(String currentUserId, String otherUserId) async {
    final firestore = _firebaseService.firestore;
    final storage = _firebaseService.storage;
    final snapshot = await firestore
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
              final ref = storage.refFromURL(url);
              await ref.delete();
            } catch (_) {}
          }
          await msg.reference.delete();
        }
        await doc.reference.delete();
        break;
      }
    }
  }

  static Future<void> addOrRemoveReaction(String conversationId, String messageId, String reactionKey) async {
    final currentUserId = _firebaseService.currentUser?.uid;
    if (currentUserId == null) return;
    final messageRef = _firebaseService.firestore
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

  static Future updateUserInfoInMessages(String userId, String newUsername, String newAvatarUrl) async {
    try {
      final batch = _firebaseService.firestore.batch();

      final conversationsQuery = await _firebaseService.firestore
          .collection('conversations')
          .where('members', arrayContains: userId)
          .get();

      for (var convDoc in conversationsQuery.docs) {
        final messagesQuery = await convDoc.reference
            .collection('messages')
            .where('sender_uid', isEqualTo: userId)
            .get();

        for (var msgDoc in messagesQuery.docs) {
          batch.update(msgDoc.reference, {
            'sender_name': newUsername,
            'sender_avatar': newAvatarUrl,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating user info in messages: $e');
      rethrow;
    }
  }
}