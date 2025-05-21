import 'package:get/get.dart';
import '../controllers/searchfl_controller.dart';
import '../services/firebase_service.dart';
import '../services/post_service.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostService>(() => PostService(Get.find<FirebaseService>()));
    Get.lazyPut<SearchFlutterController>(() => SearchFlutterController());
  }
}