class UserModel {
  final String uid;
  final String name;
  final String username;
  final String avatar;
  final String? lastMessage;
  final String? lastSenderUid;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.avatar,
    this.lastMessage,
    this.lastSenderUid,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['fullname'],
      username: map['username'],
      avatar: map['avatar_url'] ?? 'https://www.gravatar.com/avatar/placeholder?s=150&d=mp',
      lastMessage: map['last_message'],
      lastSenderUid: map['last_sender_uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullname': name,
      'username': username,
      'avatar_url': avatar,
      'last_message': lastMessage,
      'last_sender_uid': lastSenderUid,
    };
  }
}
