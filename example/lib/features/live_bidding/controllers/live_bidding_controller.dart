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
  final RxInt currentHighestBid = 1000.obs;
  final RxString highestBidderName = ''.obs;
  final RxString highestBidderId = ''.obs;
  final RxList<Map<String, dynamic>> biddingLogs = <Map<String, dynamic>>[].obs;

  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isSubmittingBid = false.obs;
  final RxBool isPulsing = false.obs;

  final RxString auctionTitle = 'live_bidding_default_item_title'.tr.obs;
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
    final idShort = currentUserId.length > 6
        ? currentUserId.substring(0, 6)
        : currentUserId;
    return 'live_bidding_bidder_prefix'.trParams({'id': idShort});
  }

  String? get currentUserAvatar {
    if (Hosteday.isInitialized) {
      return Hosteday.auth.currentUser?.avatarUrl;
    }
    return null;
  }

  bool get isCurrentHighestBidder =>
      highestBidderId.value.isNotEmpty &&
      highestBidderId.value == currentUserId;

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
        name: '$currentUserName (${'you'.tr})',
        avatarUrl: currentUserAvatar,
        joinedAt: DateTime.now(),
      ),
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

  bool _isPresenceSubscribed = false;
  bool _isPrivateSubscribed = false;
  bool _isPublicSubscribed = false;

  // ---------------------------------------------------------------------------
  // Channel Subscriptions Setup
  // ---------------------------------------------------------------------------
  Future<void> _setupPresenceAndChannels() async {
    isConnecting.value = true;
    try {
      // 1. Listen to SDK realtime connection state stream
      _streamSubscriptions.add(
        Hosteday.realtime.onConnectionStateChanged.listen((connected) {
          isConnected.value = connected;
          if (connected) {
            isConnecting.value = false;
            _subscribeChannels();
          }
        }),
      );

      // 2. Listen to Auth State Changes (e.g. user signs in while on this screen)
      if (Hosteday.isInitialized) {
        _streamSubscriptions.add(
          Hosteday.auth.authStateChanges().listen((user) {
            _ensureSelfInBidders();
            if (user != null && isConnected.value) {
              _subscribeChannels();
            }
          }),
        );
      }

      if (!Hosteday.realtime.isConnected) {
        await Hosteday.connectRealtime();
      }

      isConnected.value = Hosteday.realtime.isConnected;
      await _subscribeChannels();

      _addLog(
        title: 'live_bidding_log_radar_connected'.tr,
        description: 'live_bidding_log_connected_desc'.trParams({
          'host': Hosteday.config.realtimeHost,
        }),
        channelType: 'Realtime',
        amount: null,
      );
    } catch (e) {
      _addLog(
        title: 'live_bidding_log_connection_err'.tr,
        description: 'live_bidding_log_connection_err_desc'.trParams({
          'err': e.toString(),
        }),
        channelType: 'Error',
        amount: null,
      );
    } finally {
      isConnecting.value = false;
      isConnected.value = Hosteday.realtime.isConnected;
    }
  }

  Future<void> _subscribeChannels() async {
    // 1. Setup Public Channel (Always accessible for all users & guests)
    if (!_isPublicSubscribed) {
      try {
        await _initPublicChannel();
        _isPublicSubscribed = true;
      } catch (e) {
        debugPrint('[LiveBiddingController] Public channel notice: $e');
      }
    }

    // 2. Setup Presence & Private Channels (Only when authenticated with user token)
    if (isAuthenticated) {
      if (!_isPresenceSubscribed) {
        try {
          await _initPresenceChannel();
          _isPresenceSubscribed = true;
        } catch (e) {
          debugPrint('[LiveBiddingController] Presence channel notice: $e');
        }
      }

      if (!_isPrivateSubscribed) {
        try {
          await _initPrivateChannel();
          _isPrivateSubscribed = true;
        } catch (e) {
          debugPrint('[LiveBiddingController] Private channel notice: $e');
        }
      }
    }

    // Add self to online bidders as an active participant
    _ensureSelfInBidders();
  }

  Future<void> _initPresenceChannel() async {
    try {
      // 1. Listen for existing members present in the room (HERE / subscription_succeeded)
      final hereSub = await Hosteday.realtime.listenPresenceMembersList(
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
            title: 'live_bidding_log_joined_title'.tr,
            description: 'live_bidding_log_joined_desc'.trParams({
              'name': bidder.name,
            }),
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
                title: 'live_bidding_log_left_title'.tr,
                description: 'live_bidding_log_left_desc'.trParams({
                  'name': removed.name,
                }),
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
              hereBidders.add(
                BidderModel(
                  id: idStr,
                  name:
                      'مزايد #${idStr.length > 4 ? idStr.substring(idStr.length - 4) : idStr}',
                  joinedAt: DateTime.now(),
                ),
              );
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
          final existingIdx = onlineBidders.indexWhere(
            (b) => b.id == bidder.id,
          );
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
        title: 'live_bidding_log_here_title'.tr,
        description: 'live_bidding_log_here_desc'.trParams({
          'count': onlineBidders.length.toString(),
        }),
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
            title: 'live_bidding_log_status_updated_title'.tr,
            description: 'live_bidding_log_status_updated_desc'.tr,
            channelType: 'Public',
            amount: null,
          );
        },
      );
      _streamSubscriptions.add(publicSub);

      // Listen for public broadcast bids (allows guests to see live bids)
      final publicBidSub = await Hosteday.realtime.listenPublic(
        channel: publicChannelName,
        event: 'new-bid',
        onEvent: (event) {
          _handleIncomingWhisperBid(event.data);
        },
      );
      _streamSubscriptions.add(publicBidSub);
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
              'live_bidding_outbid_default_msg'.tr;

          hasOutbidNotice.value = true;
          lastOutbidMessage.value = msg;

          Get.snackbar(
            'live_bidding_outbid_alert_title'.tr,
            msg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
          );

          _addLog(
            title: 'live_bidding_outbid_alert_title'.tr,
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
    if (!isConnected.value || isSubmittingBid.value) return;
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
        lastOutbidMessage.value = 'live_bidding_outbid_by_msg'.trParams({
          'name': newBid.bidderName,
          'amount': newBid.amount.toString(),
        });

        Get.snackbar(
          'live_bidding_outbid_alert_title'.tr,
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
      title: isSelf
          ? 'live_bidding_log_your_bid'.tr
          : 'live_bidding_log_whisper_bid'.tr,
      description: 'live_bidding_log_bid_desc'.trParams({
        'name': bidderName,
        'amount': amount.toString(),
      }),
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
            'live_bidding_push_notification_default_title'.tr;
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
      name: '$currentUserName (${'you'.tr})',
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
