import 'package:get/get.dart';

import 'controllers/live_bidding_controller.dart';

/// GetX dependency binding for the Live Bidding Radar feature.
class LiveBiddingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveBiddingController>(() => LiveBiddingController());
  }
}

