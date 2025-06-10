import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';

class HashtagModel {
  final String id;
  final int count;

  HashtagModel({
    required this.id,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'count': count,
    };
  }

  factory HashtagModel.fromMap(String id, Map<String, dynamic> map) {
    return HashtagModel(
      id: id,
      count: map['count'] ?? 0,
    );
  }
}

class HashtagModelSnapshot {
  static final FirebaseService _firebaseService = FirebaseService();

  static Stream<List<String>> hashtagsByPrefix(String prefix) {
    return _firebaseService.firestore
        .collection('hashtags')
        .orderBy(FieldPath.documentId)
        .startAt([prefix])
        .endAt(['$prefix\uf8ff'])
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => doc.id)
        .where((tag) => tag.isNotEmpty)
        .toList());
  }
}