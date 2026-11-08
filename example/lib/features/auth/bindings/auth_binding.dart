import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// Binds [AuthController] for authentication pages.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
  }
}

