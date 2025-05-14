import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../ services/firebase_service.dart';
import '../models/user_model.dart';

class MessagesController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  String currentUserId = '';
  String currentUsername = '';

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    currentUserId = user.uid;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    if (userDoc.exists) {
      currentUsername = userDoc.data()?['username'] ?? '';
      update();
    }
  }

  Stream<List<UserModel>> getRecentConversationsStream() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return _firebaseService.getRecentConversations(currentUserId);
  }

  Stream<List<UserModel>> getSuggestionsStream() {
    if (currentUserId.isEmpty) return Stream.value([]);
    return _firebaseService.getFilteredSuggestionsStream(currentUserId);
  }

  Future<void> deleteConversationAndMessages(String otherUserId) async {
    await _firebaseService.deleteConversation(currentUserId, otherUserId);
    update(); // để làm mới UI nếu cần
  }
}
