import 'package:get/get.dart';

import '../../live_bidding/controllers/live_bidding_controller.dart';
import '../controllers/home_controller.dart';

/// Dependency injection binding for [HomeShell].
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<LiveBiddingController>(() => LiveBiddingController());
  }
}
