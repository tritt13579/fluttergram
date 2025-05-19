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

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations/$conversationId/messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => MessageModel.fromMap(e.data())).toList());
  }

  Future<void> sendMessage(String conversationId, MessageModel message) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final messageData = {
      'sender_uid': message.senderUid,
      'sender_name': message.senderName,
      'sender_avatar': message.senderAvatar,
      'receiver_uid': message.receiverUid,
      'message': message.message,
      'createdAt': Timestamp.fromDate(message.timestamp),
    };

    final conversationData = {
      'members': [message.senderUid, message.receiverUid],
      'last_message': message.message,
      'last_sender_uid': message.senderUid,
      'timestamp': Timestamp.fromDate(message.timestamp),
    };

    final exists = (await conversationRef.get()).exists;
    if (!exists) await conversationRef.set(conversationData);

    await conversationRef.collection('messages').add(messageData);
    await conversationRef.update(conversationData);
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        final members = List<String>.from(doc['members']);
        final otherUserId = members.firstWhere((id) => id != currentUserId);

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userData['last_message'] = doc['last_message'];
          userData['last_sender_uid'] = doc['last_sender_uid'];
          users.add(UserModel.fromMap(userData));
        }
      }
      return users;
    });
  }
}