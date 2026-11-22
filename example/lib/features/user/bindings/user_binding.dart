import 'package:get/get.dart';

import '../controllers/user_controller.dart';

/// Binds UserController for dependency injection.
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
  }
}
