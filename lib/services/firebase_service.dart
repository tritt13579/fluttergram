import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;

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
}