import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../models/bid_event_model.dart';
import '../models/bidder_model.dart';

/// Reactive GetX controller orchestrating the Live Bidding Radar.
///
/// Implements three-channel architecture (Presence, Public, Private)
/// alongside client-side Whisper events and FCM notifications.
class LiveBiddingController extends GetxController {
  static const String presenceChannelName = 'auction.room';
  static const String publicChannelName = 'auction-global';
  static const String whisperEventName = 'client-new-bid';

  // ---------------------------------------------------------------------------
  // Reactive State Variables
  // ---------------------------------------------------------------------------
  final RxList<BidderModel> onlineBidders = <BidderModel>[].obs;
  final RxInt currentHighestBid = 1450.obs;
  final RxString highestBidderName = 'سالم الهاشمي'.obs;
  final RxString highestBidderId = 'bidder_initial_01'.obs;
  final RxList<Map<String, dynamic>> biddingLogs = <Map<String, dynamic>>[].obs;

  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isSubmittingBid = false.obs;
  final RxBool isPulsing = false.obs;

  final RxString auctionTitle =
      'ساعة رولكس دايتونا النادرة - إصدار خاص 2024'.obs;
  final RxString auctionStatus = 'active'.obs;
  final RxInt remainingSeconds = 1800.obs; // 30 minutes

  final RxBool hasOutbidNotice = false.obs;
  final RxString lastOutbidMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // Internal Subscriptions & Timers
  // ---------------------------------------------------------------------------
  final List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  Timer? _countdownTimer;
  Timer? _pulseResetTimer;

  // ---------------------------------------------------------------------------
  // User Identity Helpers
  // ---------------------------------------------------------------------------
  bool get isAuthenticated =>
      Hosteday.isInitialized && Hosteday.auth.currentUser != null;

  late final String _guestSessionId =
      'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';

  String get currentUserId {
    if (Hosteday.isInitialized) {
      final user = Hosteday.auth.currentUser;
      if (user != null && user.id.isNotEmpty) return user.id;
    }
    return _guestSessionId;
  }

  String get currentUserName {
    if (Hosteday.isInitialized) {
      final user = Hosteday.auth.currentUser;
      final name = user?.name;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return 'مزايد ${currentUserId.length > 6 ? currentUserId.substring(0, 6) : currentUserId}';
  }

  String? get currentUserAvatar {
    if (Hosteday.isInitialized) {
      return Hosteday.auth.currentUser?.avatarUrl;
    }
    return null;
  }

  bool get isCurrentHighestBidder => highestBidderId.value == currentUserId;

  // Initial active auction participants to keep the radar fully populated
  static final List<BidderModel> _defaultInitialBidders = <BidderModel>[
    BidderModel(
      id: 'bidder_initial_01',
      name: 'سالم الهاشمي',
      avatarUrl: null,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    BidderModel(
      id: 'bidder_initial_02',
      name: 'فهد الشمري',
      avatarUrl: null,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    BidderModel(
      id: 'bidder_initial_03',
      name: 'نورة العتيبي',
      avatarUrl: null,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initBiddersRoster();
    _startCountdownTimer();
    _listenToPushNotifications();
    _setupPresenceAndChannels();
  }

  void _initBiddersRoster() {
    onlineBidders.assignAll(<BidderModel>[
      BidderModel(
        id: currentUserId,
        name: '$currentUserName (أنت)',
        avatarUrl: currentUserAvatar,
        joinedAt: DateTime.now(),
      ),
      ..._defaultInitialBidders,
    ]);
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _pulseResetTimer?.cancel();

    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _streamSubscriptions.clear();

    _leaveAllChannels();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Channel Subscriptions Setup
  // ---------------------------------------------------------------------------
  Future<void> _setupPresenceAndChannels() async {
    isConnecting.value = true;
    try {
      if (!Hosteday.realtime.isConnected) {
        await Hosteday.connectRealtime();
      }

      isConnected.value = Hosteday.realtime.isConnected;

      // 1. Setup Public Channel (Always accessible for all users & guests)
      try {
        await _initPublicChannel();
      } catch (e) {
        debugPrint('[LiveBiddingController] Public channel notice: $e');
      }

      // 2. Setup Presence Channel (Radar of active participants & Whisper)
      try {
        await _initPresenceChannel();
      } catch (e) {
        debugPrint('[LiveBiddingController] Presence channel notice: $e');
      }

      // 3. Setup Private Channel (Personal outbid alerts for authenticated users)
      try {
        await _initPrivateChannel();
      } catch (e) {
        debugPrint('[LiveBiddingController] Private channel notice: $e');
      }

      // Add self to online bidders as an active participant
      _ensureSelfInBidders();

      _addLog(
        title: 'اتصال رادار المزايدة',
        description: 'تم الاتصال بنجاح بخادم الويب سوكت (${Hosteday.config.realtimeHost}) والقنوات الحية',
        channelType: 'Realtime',
        amount: null,
      );
    } catch (e) {
      _addLog(
        title: 'تنبيه اتصال',
        description: 'تعذر الاتصال بالخادم: $e',
        channelType: 'Error',
        amount: null,
      );
    } finally {
      isConnecting.value = false;
      isConnected.value = Hosteday.realtime.isConnected;
    }
  }

  Future<void> _initPresenceChannel() async {
    try {
      // 1. Listen for existing members present in the room (HERE / subscription_succeeded)
      final hereSub = await Hosteday.realtime.listenPresenceHere(
        channel: presenceChannelName,
        onEvent: (event) {
          _handlePresenceHere(event.data);
        },
      );
      _streamSubscriptions.add(hereSub);

      // 2. Listen for joining members (JOINING)
      final addSub = await Hosteday.realtime.listenPresenceMemberAdded(
        channel: presenceChannelName,
        onEvent: (event) {
          final bidder = BidderModel.fromPresenceMap(event.data);
          if (bidder.id.isNotEmpty) {
            final idx = onlineBidders.indexWhere((b) => b.id == bidder.id);
            if (idx >= 0) {
              onlineBidders[idx] = bidder;
            } else {
              onlineBidders.add(bidder);
            }
          }
          _addLog(
            title: 'انضمام مزايد جديد',
            description: '${bidder.name} انضم إلى رادار المزايدة الآن',
            channelType: 'Presence',
            amount: null,
          );
        },
      );
      _streamSubscriptions.add(addSub);

      // 3. Listen for leaving members (LEAVING)
      final removeSub = await Hosteday.realtime.listenPresenceMemberRemoved(
        channel: presenceChannelName,
        onEvent: (event) {
          final id = (event.data['id'] ?? event.data['user_id'])?.toString();
          if (id != null && id.isNotEmpty) {
            final removed = onlineBidders.firstWhereOrNull((b) => b.id == id);
            if (id != currentUserId) {
              onlineBidders.removeWhere((b) => b.id == id);
            }
            if (removed != null) {
              _addLog(
                title: 'مغادرة مزايد',
                description: '${removed.name} غادر غرفة المزايدة',
                channelType: 'Presence',
                amount: null,
              );
            }
          }
        },
      );
      _streamSubscriptions.add(removeSub);

      // 4. Listen for Whisper events (Live client-to-client bids)
      final whisperSub = await Hosteday.realtime.listen(
        channel: presenceChannelName,
        event: whisperEventName,
        type: HostedayChannelType.presence,
        onEvent: (event) {
          _handleIncomingWhisperBid(event.data);
        },
      );
      _streamSubscriptions.add(whisperSub);
    } catch (e) {
      debugPrint('[LiveBiddingController] Presence setup note: $e');
    }
  }

  /// Parses and displays members returned by the 'here' (subscription_succeeded) event.
  void _handlePresenceHere(dynamic rawData) {
    try {
      dynamic data = rawData;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      final List<BidderModel> hereBidders = <BidderModel>[];

      // Format 1: Laravel Echo array of user objects: [ {id, name, ...}, ... ]
      if (data is List) {
        for (final item in data) {
          final bidder = BidderModel.fromPresenceMap(item);
          if (bidder.id.isNotEmpty &&
              !hereBidders.any((b) => b.id == bidder.id)) {
            hereBidders.add(bidder);
          }
        }
      }
      // Format 2: Pusher/Reverb standard presence payload
      else if (data is Map) {
        final presence = data['presence'];
        if (presence is Map) {
          final hash = presence['hash'];
          if (hash is Map) {
            hash.forEach((key, val) {
              final id = key.toString();
              final bidder = BidderModel.fromPresenceMember(id, val);
              if (bidder.id.isNotEmpty &&
                  !hereBidders.any((b) => b.id == bidder.id)) {
                hereBidders.add(bidder);
              }
            });
          } else if (presence['ids'] is List) {
            for (final id in (presence['ids'] as List)) {
              final idStr = id.toString();
              hereBidders.add(BidderModel(
                id: idStr,
                name:
                    'مزايد #${idStr.length > 4 ? idStr.substring(idStr.length - 4) : idStr}',
                joinedAt: DateTime.now(),
              ));
            }
          }
        } else if (data['members'] is List) {
          for (final item in (data['members'] as List)) {
            final bidder = BidderModel.fromPresenceMap(item);
            if (bidder.id.isNotEmpty &&
                !hereBidders.any((b) => b.id == bidder.id)) {
              hereBidders.add(bidder);
            }
          }
        } else if (data['members'] is Map) {
          (data['members'] as Map).forEach((key, val) {
            final id = key.toString();
            final bidder = BidderModel.fromPresenceMember(id, val);
            if (bidder.id.isNotEmpty &&
                !hereBidders.any((b) => b.id == bidder.id)) {
              hereBidders.add(bidder);
            }
          });
        }
      }

      // Merge / update onlineBidders with members from 'here'
      if (hereBidders.isNotEmpty) {
        for (final bidder in hereBidders) {
          final existingIdx =
              onlineBidders.indexWhere((b) => b.id == bidder.id);
          if (existingIdx >= 0) {
            onlineBidders[existingIdx] = bidder;
          } else {
            onlineBidders.add(bidder);
          }
        }
      }

      // Ensure self is in onlineBidders at index 0
      _ensureSelfInBidders();

      _addLog(
        title: 'رادار المتواجدين (Here)',
        description:
            'تم مسح ومزامنة أعضاء الغرفة (${onlineBidders.length} متواجد متكامل)',
        channelType: 'Presence',
        amount: null,
      );
    } catch (e) {
      debugPrint('[LiveBiddingController] Error handling here event: $e');
    }
  }

  Future<void> _initPublicChannel() async {
    try {
      final publicSub = await Hosteday.realtime.listenPublic(
        channel: publicChannelName,
        event: 'AuctionStatusChanged',
        onEvent: (event) {
          final status = event.data['status']?.toString();
          if (status != null) {
            auctionStatus.value = status;
          }
          final title = event.data['title']?.toString();
          if (title != null) {
            auctionTitle.value = title;
          }
          final seconds = event.data['remaining_seconds'];
          if (seconds != null) {
            remainingSeconds.value =
                int.tryParse(seconds.toString()) ?? remainingSeconds.value;
          }
          _addLog(
            title: 'تحديث حالة المزاد',
            description: 'تم تحديث حالة المزاد عبر القناة العامة',
            channelType: 'Public',
            amount: null,
          );
        },
      );
      _streamSubscriptions.add(publicSub);
    } catch (e) {
      debugPrint('[LiveBiddingController] Public channel setup note: $e');
    }
  }

  Future<void> _initPrivateChannel() async {
    try {
      final privateChannel = 'user.$currentUserId';
      final privateSub = await Hosteday.realtime.listenPrivate(
        channel: privateChannel,
        event: 'OutbidNotification',
        onEvent: (event) {
          final msg =
              event.data['message']?.toString() ??
              'تنبيه: قام شخص آخر بتجاوز عرضك الأخير في المزاد!';

          hasOutbidNotice.value = true;
          lastOutbidMessage.value = msg;

          Get.snackbar(
            '⚠️ تم تجاوز عرضك!',
            msg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
          );

          _addLog(
            title: 'تنبيه تجاوز العرض (Outbid)',
            description: msg,
            channelType: 'Private',
            amount: null,
          );
        },
      );
      _streamSubscriptions.add(privateSub);
    } catch (e) {
      debugPrint('[LiveBiddingController] Private channel setup note: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Bidding Actions & Whisper Dispatch
  // ---------------------------------------------------------------------------
  /// Submits an immediate bid increment using client-side Whisper.
  Future<void> submitBid(int increment) async {
    if (isSubmittingBid.value) return;
    isSubmittingBid.value = true;

    try {
      final newAmount = currentHighestBid.value + increment;
      final eventPayload = BidEventModel(
        bidderId: currentUserId,
        bidderName: currentUserName,
        amount: newAmount,
        timestamp: DateTime.now(),
      ).toJson();

      // 1. Dispatch Whisper directly through Presence Channel
      try {
        final presence = await Hosteday.realtime.presenceChannel(
          presenceChannelName,
        );
        presence.trigger(eventName: whisperEventName, data: eventPayload);
      } catch (whisperError) {
        debugPrint(
          '[LiveBiddingController] Whisper wire notice: $whisperError',
        );
      }

      // 2. Optimistic local update
      _applyBid(
        amount: newAmount,
        bidderName: currentUserName,
        bidderId: currentUserId,
        isSelf: true,
      );

      hasOutbidNotice.value = false;

      Get.snackbar(
        '🎯 تم تقديم العرض بنجاح',
        'أنت الآن صاحب أعلى مزايدة بقيمة \$$newAmount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ في تقديم العرض',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSubmittingBid.value = false;
    }
  }

  void _handleIncomingWhisperBid(dynamic rawData) {
    Map<String, dynamic> data = <String, dynamic>{};
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final newBid = BidEventModel.fromJson(data);
    if (newBid.amount > currentHighestBid.value) {
      final wasSelfHighest = isCurrentHighestBidder;
      final isNewBidFromSelf = newBid.bidderId == currentUserId;

      _applyBid(
        amount: newBid.amount,
        bidderName: newBid.bidderName,
        bidderId: newBid.bidderId,
        isSelf: isNewBidFromSelf,
      );

      // If user was previously the leader and got outbid by someone else
      if (wasSelfHighest && !isNewBidFromSelf) {
        hasOutbidNotice.value = true;
        lastOutbidMessage.value =
            'قام ${newBid.bidderName} بتقديم عرض أعلى منك بقيمة \$${newBid.amount}!';

        Get.snackbar(
          '⚠️ تم كسر عرضك!',
          lastOutbidMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  void _applyBid({
    required int amount,
    required String bidderName,
    required String bidderId,
    required bool isSelf,
  }) {
    currentHighestBid.value = amount;
    highestBidderName.value = bidderName;
    highestBidderId.value = bidderId;

    _triggerPulseAnimation();

    _addLog(
      title: isSelf ? 'عرضك الجديد' : 'مزايدة جديدة (Whisper)',
      description: '$bidderName قدّم مزايدة بقيمة \$$amount',
      channelType: 'Presence Whisper',
      amount: amount,
    );
  }

  void _triggerPulseAnimation() {
    isPulsing.value = true;
    _pulseResetTimer?.cancel();
    _pulseResetTimer = Timer(const Duration(milliseconds: 700), () {
      isPulsing.value = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Push Notifications Listening (FCM v1)
  // ---------------------------------------------------------------------------
  void _listenToPushNotifications() {
    try {
      final sub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title =
            message.notification?.title ??
            message.data['title'] ??
            'إشعار مزاد مباشر';
        final body =
            message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            '';

        _addLog(
          title: title,
          description: body,
          channelType: 'FCM Push',
          amount: null,
        );

        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1E1E28),
          colorText: Colors.white,
          icon: const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFF38BDF8),
          ),
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      });
      _streamSubscriptions.add(sub);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helper Routines
  // ---------------------------------------------------------------------------
  void _ensureSelfInBidders() {
    final selfBidder = BidderModel(
      id: currentUserId,
      name: '$currentUserName (أنت)',
      avatarUrl: currentUserAvatar,
      joinedAt: DateTime.now(),
    );

    final idx = onlineBidders.indexWhere((b) => b.id == currentUserId);
    if (idx >= 0) {
      onlineBidders[idx] = selfBidder;
    } else {
      onlineBidders.insert(0, selfBidder);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        auctionStatus.value = 'ended';
        timer.cancel();
      }
    });
  }

  void _addLog({
    required String title,
    required String description,
    required String channelType,
    required int? amount,
  }) {
    final item = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'channel_type': channelType,
      'amount': amount,
      'timestamp': DateTime.now(),
    };
    biddingLogs.insert(0, item);
    if (biddingLogs.length > 50) {
      biddingLogs.removeLast();
    }
  }

  void _leaveAllChannels() {
    try {
      Hosteday.realtime.unsubscribe(
        presenceChannelName,
        type: HostedayChannelType.presence,
      );
      Hosteday.realtime.unsubscribe(
        publicChannelName,
        type: HostedayChannelType.public,
      );
      Hosteday.realtime.unsubscribe(
        'user.$currentUserId',
        type: HostedayChannelType.private,
      );
    } catch (_) {}
  }

  String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String formatCountdown(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
