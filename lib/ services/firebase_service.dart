import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

  // Authentication services
  Future<UserCredential> signUp({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Firestore services
  Future<void> createDocument({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final CollectionReference collectionRef = _firestore.collection(collection);
      if (documentId != null) {
        await collectionRef.doc(documentId).set(data);
      } else {
        await collectionRef.add(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      rethrow;
    }
  }

  Stream<DocumentSnapshot> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  Stream<QuerySnapshot> streamCollection({
    required String collection,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  // Firebase Storage services
  Future<String> uploadImage({
    required File image,
    required String path,
    bool upsert = false,
  }) async {
    try {
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> updateImage({
    required File image,
    required String path,
    bool upsert = false,
  }) async {
    try {
      final String downloadUrl = await uploadImage(
          image: image,
          path: path,
          upsert: true
      );
      // Adding timestamp query parameter to force refresh on UI
      return "$downloadUrl?ts=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteImage({required String path}) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      rethrow;
    }
  }


  // Firebase Cloud Messaging services
  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  Future<void> saveDeviceToken({required String userId, required String token}) async {
    await _firestore.collection('users').doc(userId).collection('tokens').doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  }

  Future<void> removeDeviceToken({required String userId, required String token}) async {
    await _firestore.collection('users').doc(userId).collection('tokens').doc(token).delete();
  }

  // Initialize Firebase messaging
  Future<void> initMessaging() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save token if permission granted
    if (settings.authorizationStatus == AuthorizationStatus.authorized && userId != null) {
      String? token = await getDeviceToken();
      if (token != null) {
        await saveDeviceToken(userId: userId!, token: token);
      }
    }
  }

  // Message stream
  Stream<List<MessageModel>> getMessagesStream(String conversationId) =>
      _firestore
          .collection('conversations/$conversationId/messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs.map(
            (doc) => MessageModel.fromMap(doc.data(), id: doc.id),
      ).toList());

  // Send message
  Future<void> sendMessage(String conversationId, MessageModel msg) async {
    final ref = _firestore.collection('conversations').doc(conversationId);
    final msgData = {
      'sender_uid': msg.senderUid,
      'sender_name': msg.senderName,
      'sender_avatar': msg.senderAvatar,
      'receiver_uid': msg.receiverUid,
      'message': msg.message,
      'createdAt': Timestamp.fromDate(msg.timestamp),
    };
    final convData = {
      'members': [msg.senderUid, msg.receiverUid],
      'last_message': msg.message,
      'last_sender_uid': msg.senderUid,
      'timestamp': Timestamp.fromDate(msg.timestamp),
    };

    if (!(await ref.get()).exists) await ref.set(convData);
    await ref.collection('messages').add(msgData);
    await ref.update(convData);
  }

  // Delete conversation with specific user
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
          await msg.reference.delete();
        }
        await doc.reference.delete();
        break;
      }
    }
  }

  // All users stream
  Stream<List<UserModel>> getUsersStream() => _firestore
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((e) => UserModel.fromMap(e.data())).toList());

  // Recent conversations stream
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
    return _firestore.collection('users').snapshots().asyncMap((snapshot) async {
      // Lấy danh sách userId đã trò chuyện
      final conversations = await _firestore
          .collection('conversations')
          .where('members', arrayContains: currentUserId)
          .get();

      final existingUserIds = conversations.docs
          .map((doc) => List<String>.from(doc['members'])
          .firstWhere((id) => id != currentUserId))
          .toSet();

      // Lọc ra những người dùng chưa từng trò chuyện
      final allUsers = snapshot.docs.map((doc) => UserModel.fromMap(doc.data()));
      return allUsers
          .where((user) =>
      user.uid != currentUserId && !existingUserIds.contains(user.uid))
          .toList();
    });
  }
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      final messagesRef = _firestore.collection('conversations/$conversationId/messages');

      // Xóa tin nhắn
      await messagesRef.doc(messageId).delete();

      // Lấy lại tin nhắn cuối cùng còn lại sau khi xóa
      final lastMessageQuery = await messagesRef
          .orderBy('createdAt', descending: true) // Đúng tên trường
          .limit(1)
          .get();

      if (lastMessageQuery.docs.isNotEmpty) {
        final lastMessageDoc = lastMessageQuery.docs.first;
        await _firestore.collection('conversations').doc(conversationId).update({
          'last_message': lastMessageDoc['message'],
          'last_sender_uid': lastMessageDoc['sender_uid'],
        });
      } else {
        await _firestore.collection('conversations').doc(conversationId).update({
          'last_message': '',
          'last_sender_uid': '',
        });
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<void> updateMessage(String conversationId, String messageId, String newContent) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final docRef = messagesRef.doc(messageId);

    await docRef.update({
      'message': newContent,
      'editedTimestamp': DateTime.now(),
    });

    // Lấy tin nhắn cuối cùng để so sánh
    final lastMessageQuery = await messagesRef
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (lastMessageQuery.docs.isNotEmpty &&
        lastMessageQuery.docs.first.id == messageId) {
      // Nếu message vừa cập nhật là tin nhắn cuối cùng thì cập nhật vào conversations
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'last_message': newContent,
        'last_sender_uid': lastMessageQuery.docs.first['sender_uid'],
        'timestamp': Timestamp.now(), // Có thể cập nhật lại timestamp nếu muốn cập nhật lại vị trí sort
      });
    }
  }

}