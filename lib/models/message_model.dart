import 'package:cloud_firestore/cloud_firestore.dart';

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