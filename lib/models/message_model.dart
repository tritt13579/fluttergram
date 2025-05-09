import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderUid;
  final String senderName;
  final String senderAvatar;
  final String receiverUid;
  final String message;
  final DateTime timestamp;

  MessageModel({
    required this.senderUid,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverUid,
    required this.message,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderUid: map['sender_uid'],
      senderName: map['sender_name'],
      senderAvatar: map['sender_avatar'],
      receiverUid: map['receiver_uid'],
      message: map['message'],
      timestamp: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
