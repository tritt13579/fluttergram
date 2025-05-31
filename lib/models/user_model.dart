import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String fullname;
  final String bio;
  final String avatarUrl;
  final DateTime createdAt;
  final int postCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.fullname,
    required this.bio,
    required this.avatarUrl,
    required this.createdAt,
    required this.postCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'fullname': fullname,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'post_count': postCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      fullname: map['fullname'] ?? '',
      bio: map['bio'] ?? '',
      avatarUrl: map['avatar_url'] ?? 'https://firebasestorage.googleapis.com/v0/b/fluttergram-5077d.appspot.com/o/avatars%2Fdefaul%2Fdefaults.jpg?alt=media',
      createdAt: (map['created_at'] is Timestamp)
          ? (map['created_at'] as Timestamp).toDate()
          : (map['created_at'] is DateTime)
          ? map['created_at'] as DateTime
          : DateTime.now(),
      postCount: map['post_count'] ?? 0,
    );
  }
}

class UserModelSnapshot {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static StreamSubscription<DocumentSnapshot>? _subscription;

  static Future<List<UserModel>> fetchAllUsers() async {
    final snap = await _firestore
        .collection('users')
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  static Future<Map<String, UserModel>> getMapUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!);
        return {uid: user};
      }
      return {};
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  static void listenDataChange(Map<String, UserModel> maps, {Function()? updateUI}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _subscription = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!);
        maps[uid] = user;
        updateUI?.call();
      }
    });
  }

  static void unsubscribeListenChange() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<List<UserModel>> fetchUserModelsByPrefix(String prefix) async {
    final snap = await _firestore
        .collection('users')
        .orderBy('username')
        .startAt([prefix])
        .endAt(['$prefix\uf8ff'])
        .limit(10)
        .get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Stream<List<String>> usernamesByPrefix(String prefix) {
    return _firestore
        .collection('users')
        .orderBy('username')
        .startAt([prefix])
        .endAt(['$prefix\uf8ff'])
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => doc['username']?.toString() ?? '')
        .where((username) => username.isNotEmpty)
        .toList());
  }

  static Future<void> insert(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error inserting user: $e');
      rethrow;
    }
  }

  static Future<void> update(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  static Future<void> delete(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}