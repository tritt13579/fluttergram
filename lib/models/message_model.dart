import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'user_model.dart';

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

/// --- Class MessageSnapshot: chứa toàn bộ logic tương tác với Firebase (Firestore & Storage)
/// --- Mọi hàm nào chạm đến `collection`, `doc`, `FirebaseStorage` đều được chuyển vào đây.
class MessageSnapshot {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 1. Lấy Stream danh sách MessageModel theo conversationId
  static Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  /// 2. Gửi tin nhắn (cả text và image URLs)
  static Future<void> sendMessage(
      String conversationId,
      MessageModel msg, {
        List<String> imageUrls = const [],
      }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);

    // Dữ liệu cho message mới
    final msgData = {
      'sender_uid': msg.senderUid,
      'sender_name': msg.senderName,
      'sender_avatar': msg.senderAvatar,
      'receiver_uid': msg.receiverUid,
      'message': msg.message,
      'createdAt': Timestamp.fromDate(msg.timestamp),
      'images': imageUrls,
      'reactions': {}, // mặc định chưa có reaction
    };

    // Dữ liệu cập nhật hoặc tạo mới cho conversation
    final convData = {
      'members': [msg.senderUid, msg.receiverUid],
      'last_message': msg.message.isNotEmpty
          ? msg.message
          : (imageUrls.isNotEmpty ? '[Hình ảnh]' : ''),
      'last_sender_uid': msg.senderUid,
      'timestamp': Timestamp.fromDate(msg.timestamp),
    };

    // Nếu conversation chưa tồn tại thì tạo mới
    if (!(await convRef.get()).exists) {
      await convRef.set(convData);
    }

    // Thêm message vào sub-collection
    await convRef.collection('messages').add(msgData);

    // Cập nhật lại thông tin cuối cùng của cuộc trò chuyện
    await convRef.update(convData);
  }

  /// 3. Xóa một tin nhắn
  static Future<void> deleteMessage(
      String conversationId, String messageId) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final messageSnapshot = await messageRef.get();
    if (messageSnapshot.exists) {
      final data = messageSnapshot.data();
      final List<dynamic> imageUrls = data?['images'] ?? [];

      // Xóa tất cả hình ảnh đính kèm (nếu có)
      for (String url in imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (_) {
          // Có thể log lỗi nếu cần
        }
      }

      // Xóa document tin nhắn
      await messageRef.delete();
    }

    // Cập nhật lại last_message cho conversation
    final lastMessageQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
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
      // Nếu đã không còn tin nhắn nào
      await _firestore.collection('conversations').doc(conversationId).update({
        'last_message': '',
        'last_sender_uid': '',
        'timestamp': null,
      });
    }
  }

  /// 4. Xóa toàn bộ cuộc trò chuyện (và tất cả message con) giữa 2 user
  static Future<void> deleteConversation(
      String currentUserId, String otherUserId) async {
    // Tìm tất cả conversation có currentUserId
    final snapshot = await _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .get();

    for (var doc in snapshot.docs) {
      final members = List<String>.from(doc['members']);
      if (members.contains(otherUserId)) {
        // Xóa từng message con trong conversation đó
        final messages = await doc.reference.collection('messages').get();
        for (var msg in messages.docs) {
          final data = msg.data();
          final List<dynamic> imageUrls = data['images'] ?? [];
          for (String url in imageUrls) {
            try {
              final ref = _storage.refFromURL(url);
              await ref.delete();
            } catch (_) {}
          }
          await msg.reference.delete();
        }

        // Xóa document conversation
        await doc.reference.delete();
        break;
      }
    }
  }

  /// 5. Stream List<UserModel> các cuộc trò chuyện gần nhất của currentUserId
  static Stream<List<UserModel>> getRecentConversations(
      String currentUserId) {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> users = [];

      for (var doc in snapshot.docs) {
        final members = List<String>.from(doc['members']);
        final otherUserId = members.firstWhere((id) => id != currentUserId);

        final userDoc =
        await _firestore.collection('users').doc(otherUserId).get();
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

  /// 6. Stream List<UserModel> gợi ý (chưa chat) cho currentUserId
  static Stream<List<UserModel>> getFilteredSuggestionsStream(
      String currentUserId) {
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
      user.uid != currentUserId &&
          !existingUserIds.contains(user.uid))
          .toList();

      controller.add(suggestions);
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// 7. Xóa conversation và messages (gọi hàm deleteConversation)
  static Future<void> deleteConversationAndMessages(
      String currentUserId, String otherUserId) async {
    await deleteConversation(currentUserId, otherUserId);
  }

  /// 8. Tạo conversationId từ 2 uid (không chạm Firebase)
  static String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// 9. Upload một danh sách ảnh lên Firebase Storage, trả về List URLs
  static Future<List<String>> uploadImages(
      List<File> images, String path) async {
    List<String> imageUrls = [];

    for (var image in images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('$path/$fileName');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  /// 10. Thêm hoặc gỡ reaction vào một tin nhắn
  static Future<void> addOrRemoveReaction(
      String conversationId, String messageId, String reactionKey) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    Map<String, dynamic> reactions = Map<String, dynamic>.from(
        data['reactions'] ?? {});

    if (reactions[currentUserId] == reactionKey) {
      reactions.remove(currentUserId);
    } else {
      reactions[currentUserId] = reactionKey;
    }

    await messageRef.update({'reactions': reactions});
  }

  /// 11. Đếm số bài viết (posts) của một user (nếu cần)
  static Future<int> countUserPosts(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      return querySnapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
