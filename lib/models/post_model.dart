import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String caption;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final List<String> taggedUsers;
  final DateTime createdAt;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.userId,
    required this.caption,
    required this.mediaUrls,
    required this.hashtags,
    required this.taggedUsers,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'hashtags': hashtags,
      'taggedUsers': taggedUsers,
      'createdAt': createdAt,
      'likes': likes,
      'comments': comments,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      caption: map['caption'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      createdAt: map['createdAt'].toDate(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
    );
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      caption: data['caption'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      taggedUsers: List<String>.from(data['taggedUsers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }
}