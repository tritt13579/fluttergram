import 'package:get/get.dart';

class MessagesController extends GetxController {
  int selectedTab = 0;
  List<Map<String, String>> suggestions = [
    {
      'name': 'Huỳnh Huy',
      'username': 'huynhhuy79996',
      'avatar': 'https://via.placeholder.com/150',
    },
    {
      'name': 'binhnguyen611',
      'username': 'binhnguyen61104',
      'avatar': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Mobile VN',
      'username': 'mobilevn',
      'avatar': 'https://via.placeholder.com/150',
    },
  ];

  List<Map<String, String>> recommended = [
    {
      'name': 'Như Thùy',
      'username': 'nhuthuy',
      'avatar': 'https://via.placeholder.com/150',
    },
    {
      'name': 'phnt6666',
      'username': 'phnt6666',
      'avatar': 'https://via.placeholder.com/150',
    },
  ];

  void changeTab(int tab) {
    selectedTab = tab;
    update();
  }

  void removeRecommended(int index) {
    recommended.removeAt(index);
    update();
  }

}
