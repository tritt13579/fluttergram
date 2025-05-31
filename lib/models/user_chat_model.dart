import 'dart:async';

import '../services/firebase_service.dart';

class UserChatModel {
  final String uid;
  final String fullname;
  final String username;
  final String avatarUrl;
  final String? lastMessage;
  final String? lastSenderUid;

  UserChatModel({
    required this.uid,
    required this.fullname,
    required this.username,
    required this.avatarUrl,
    this.lastMessage,
    this.lastSenderUid,
  });

  factory UserChatModel.fromMap(Map<String, dynamic> map) {
    return UserChatModel(
      uid: map['uid'] ?? '',
      fullname: map['fullname'] ?? '',
      username: map['username'] ?? '',
      avatarUrl: map['avatar_url'] ?? 'https://www.gravatar.com/avatar/placeholder?s=150&d=mp',
      lastMessage: map['last_message'],
      lastSenderUid: map['last_sender_uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullname': fullname,
      'username': username,
      'avatar_url': avatarUrl,
      'last_message': lastMessage,
      'last_sender_uid': lastSenderUid,
    };
  }
}

class UserChatModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();

  static Stream<List<UserChatModel>> getRecentConversations(String currentUserId) {
    return _firebaseService.firestore
        .collection('conversations')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserChatModel> users = [];
      for (var doc in snapshot.docs) {
        final members = List<String>.from(doc['members']);
        final otherUserId = members.firstWhere((id) => id != currentUserId);

        final userDoc = await _firebaseService.firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['last_message'] = doc['last_message'];
          data['last_sender_uid'] = doc['last_sender_uid'];
          users.add(UserChatModel.fromMap(data));
        }
      }
      return users;
    });
  }

  static Stream<List<UserChatModel>> getFilteredSuggestionsStream(String currentUserId) {
    final controller = StreamController<List<UserChatModel>>();
    final firestore = _firebaseService.firestore;

    final subscription = firestore
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

      final userSnap = await firestore.collection('users').get();

      final suggestions = userSnap.docs
          .map((doc) => UserChatModel.fromMap(doc.data()))
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
}