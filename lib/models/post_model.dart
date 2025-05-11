import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String ownerId;
  final String? ownerUsername;
  final String? ownerPhotoUrl;
  final String caption;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.ownerId,
    this.ownerUsername,
    this.ownerPhotoUrl,
    required this.caption,
    required this.mediaUrls,
    required this.hashtags,
    required this.likeCount,
    required this.commentCount,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerUsername: data['ownerUsername'],
      ownerPhotoUrl: data['ownerPhotoUrl'],
      caption: data['caption'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      ownerUsername: data['ownerUsername'],
      ownerPhotoUrl: data['ownerPhotoUrl'],
      caption: data['caption'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'ownerPhotoUrl': ownerPhotoUrl,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'hashtags': hashtags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  PostModel copyWith({
    int? likeCount,
    int? commentCount,
  }) {
    return PostModel(
      id: id,
      ownerId: ownerId,
      ownerUsername: ownerUsername,
      ownerPhotoUrl: ownerPhotoUrl,
      caption: caption,
      mediaUrls: mediaUrls,
      hashtags: hashtags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
    );
  }
}