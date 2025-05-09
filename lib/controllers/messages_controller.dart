import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../ services/firebase_service.dart';
import '../models/user_model.dart';

class MessagesController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  List<UserModel> recentMessages = [];
  List<UserModel> recommended = [];
  User? currentUser;
  String currentUsername = "";
  String currentUserId = "";

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    currentUserId = currentUser!.uid;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      currentUsername = userData!['username'] ?? 'Unknown';
    }
    _firebaseService.getUsersStream().listen((users) async {
      final otherUsers = users.where((u) => u.uid != currentUserId).toList();

      final conversationSnapshots = await FirebaseFirestore.instance
          .collection('conversations')
          .where('members', arrayContains: currentUserId)
          .get();

      final existingUserIds = <String>{};
      for (var doc in conversationSnapshots.docs) {
        final members = List<String>.from(doc['members']);
        final otherUserId = members.firstWhere((id) => id != currentUserId);
        existingUserIds.add(otherUserId);
      }

      _firebaseService.getRecentConversations(currentUserId).listen((recentUsers) {
        recentMessages = recentUsers;

        recommended = otherUsers
            .where((u) => !existingUserIds.contains(u.uid))
            .take(15)
            .toList();

        update();
      }, onError: (e) {
        recommended = otherUsers
            .where((u) => !existingUserIds.contains(u.uid))
            .take(15)
            .toList();
        update();
      });
    });
  }

  void addToRecentMessages(UserModel user) {
    if (!recentMessages.any((u) => u.uid == user.uid)) {
      recentMessages.add(user);
      update();
    }
  }

  void removeFromRecommended(UserModel user) {
    recommended.removeWhere((u) => u.uid == user.uid);
    update();
  }

  Future<void> deleteConversationAndMessages(String otherUserId) async {
    await _firebaseService.deleteConversation(currentUserId, otherUserId);
    recentMessages.removeWhere((user) => user.uid == otherUserId);

    update();
    await fetchUserData();
  }
}
