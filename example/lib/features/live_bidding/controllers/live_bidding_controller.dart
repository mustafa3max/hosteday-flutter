import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../models/auction_model.dart';
import '../models/bid_event_model.dart';
import '../models/bidder_model.dart';

/// Reactive GetX controller orchestrating the Live Bidding Radar.
///
/// Implements three-channel architecture (Presence, Public, Private)
/// alongside `auctions` / `auction_bids` persistence, automatic auction
/// rotation, official Presence broadcasts, and FCM notifications.
class LiveBiddingController extends GetxController {
  static const String defaultRoomChannel = 'auction.room';
  static const String publicChannelName = 'auction-global';
  static const String whisperEventName = 'client-new-bid';
  static const String serverBidEventName = 'AuctionBidPlaced';
  static const String auctionsPath = '/api/auctions';
  static const String auctionBidsPath = '/api/auction_bids';

  // ---------------------------------------------------------------------------
  // Reactive State Variables
  // ---------------------------------------------------------------------------
  final RxList<AuctionModel> auctions = <AuctionModel>[].obs;
  final Rxn<AuctionModel> activeAuction = Rxn<AuctionModel>();
  final RxList<BidderModel> onlineBidders = <BidderModel>[].obs;
  final RxInt currentHighestBid = 1000.obs;
  final RxString highestBidderName = ''.obs;
  final RxString highestBidderId = ''.obs;
  final RxList<Map<String, dynamic>> biddingLogs = <Map<String, dynamic>>[].obs;

  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isSubmittingBid = false.obs;
  final RxBool isPulsing = false.obs;
  final RxString connectionError = ''.obs;

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
  final List<StreamSubscription<dynamic>> _presenceStreamSubscriptions =
      <StreamSubscription<dynamic>>[];
  final Set<String> _processedBidKeys = <String>{};
  String? _subscribedPresenceChannel;
  Timer? _countdownTimer;

  /// Current per-auction channel and event name (`auction.{id}`).
  String get currentRoomChannel => activeAuction.value != null
      ? 'auction.${activeAuction.value!.id}'
      : defaultRoomChannel;
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
      final email = user?.email;
      if (email != null && email.trim().isNotEmpty) return email.trim();
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
    _loadAllAuctions();
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

    for (final sub in _presenceStreamSubscriptions) {
      sub.cancel();
    }
    _presenceStreamSubscriptions.clear();

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
  // Auctions & Per-Auction Independent Rooms (`auction.{id}`)
  // ---------------------------------------------------------------------------
  Future<void> _loadAllAuctions() async {
    if (!Hosteday.isInitialized) return;
    try {
      final response = await Hosteday.client.get(
        auctionsPath,
        withAuth: isAuthenticated,
      );

      final allAuctions =
          AuctionModel.extractRows(response)
              .map(AuctionModel.fromJson)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));

      auctions.assignAll(allAuctions);

      if (allAuctions.isNotEmpty) {
        final currentId = activeAuction.value?.id;
        final initial = currentId != null
            ? allAuctions.firstWhere(
                (a) => a.id == currentId,
                orElse: () => allAuctions.first,
              )
            : allAuctions.first;
        await selectAuction(initial);
      }
    } catch (e) {
      debugPrint('[LiveBiddingController] Failed to load auctions: $e');
    }
  }

  /// Switches to [selectedAuction], unsubscribing from the previous room
  /// (`presence-auction.$previousId`), waiting 100ms, and subscribing to `auction.${selectedAuction.id}`.
  Future<void> selectAuction(AuctionModel selectedAuction) async {
    final previousChannel = _subscribedPresenceChannel;
    final nextChannel = 'auction.${selectedAuction.id}';

    // 1. Cancel previous presence listeners and unsubscribe from previous auction room
    for (final sub in _presenceStreamSubscriptions) {
      await sub.cancel();
    }
    _presenceStreamSubscriptions.clear();
    _isPresenceSubscribed = false;

    if (Hosteday.isInitialized &&
        previousChannel != null &&
        previousChannel != nextChannel) {
      final previousPresenceName = previousChannel.startsWith('presence-')
          ? previousChannel
          : 'presence-$previousChannel';
      try {
        await Hosteday.realtime.unsubscribe(
          previousPresenceName,
          type: HostedayChannelType.presence,
        );
      } catch (e) {
        debugPrint(
          '[LiveBiddingController] Unsubscribe "$previousPresenceName" notice: $e',
        );
      }
      // Allow the server/socket to process pusher:unsubscribe before subscribing to the new room
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _subscribedPresenceChannel = null;

    // 2. Reset per-room state and apply selected auction metadata
    _processedBidKeys.clear();
    biddingLogs.clear();
    onlineBidders.clear();
    _ensureSelfInBidders();

    _applyActiveAuction(selectedAuction);

    // 3. Subscribe to the new per-auction presence channel (`presence-auction.{id}`)
    await _initPresenceChannel();

    // 4. Load bids belonging strictly to this auction
    await _loadAuctionBids(selectedAuction.id);
  }

  void _applyActiveAuction(AuctionModel auction) {
    activeAuction.value = auction;
    auctionTitle.value = auction.title;
    auctionStatus.value = 'active';
    final baselinePrice = auction.currentPrice >= auction.startingPrice
        ? auction.currentPrice
        : auction.startingPrice;
    currentHighestBid.value = baselinePrice;
    highestBidderId.value = auction.winnerId ?? '';
    highestBidderName.value = auction.winnerName ?? '';
    remainingSeconds.value = auction.remainingSecondsFrom(
      DateTime.now().toUtc(),
    );
    hasOutbidNotice.value = false;
    _startCountdownTimer();
  }

  void _updateAuctionPriceInList(
    int auctionId,
    int newPrice, {
    String? winnerId,
    String? winnerName,
  }) {
    final idx = auctions.indexWhere((a) => a.id == auctionId);
    if (idx != -1) {
      auctions[idx] = auctions[idx].copyWith(
        currentPrice: newPrice,
        winnerId: winnerId,
        winnerName: winnerName,
      );
      auctions.refresh();
    }
  }

  Future<void> _loadAuctionBids(int auctionId) async {
    try {
      final bidsRes = await Hosteday.client.get(
        auctionBidsPath,
        filters: <String, Object?>{'auction_id': auctionId},
        queryParameters: const <String, Object?>{
          'sort': '-id',
          'order_by': 'id',
          'direction': 'desc',
        },
        withAuth: isAuthenticated,
      );

      // Guard against stale async response if user switched auctions quickly
      if (activeAuction.value?.id != auctionId) return;

      final bidRows = AuctionModel.extractRows(bidsRes);
      final parsedBids = bidRows.map(BidEventModel.fromJson).toList()
        ..sort((a, b) {
          final amountCompare = b.exactAmount.compareTo(a.exactAmount);
          if (amountCompare != 0) return amountCompare;
          return b.id.compareTo(a.id);
        });

      // Compute maxAmount programmatically across all fetched rows regardless of server sort order
      double maxBidAmount = 0.0;
      BidEventModel? highestBid;
      for (final bid in parsedBids) {
        if (bid.exactAmount > maxBidAmount) {
          maxBidAmount = bid.exactAmount;
          highestBid = bid;
        }
      }

      biddingLogs.removeWhere(
        (log) =>
            (log['channel_type']?.toString().startsWith('Presence') ?? false) ||
            log['channel_type'] == 'Database',
      );

      // Insert oldest first so _addLog (which inserts at index 0) places newest/highest at the top
      for (final bid in parsedBids.reversed) {
        _processedBidKeys.add(_bidDedupKey(bid));
        _addLog(
          title: bid.bidderId == currentUserId
              ? 'live_bidding_log_your_bid'.tr
              : 'live_bidding_log_whisper_bid'.tr,
          description: 'live_bidding_log_bid_desc'.trParams({
            'name': bid.bidderName,
            'amount': bid.amount.toString(),
          }),
          channelType: 'Presence',
          amount: bid.amount,
        );
      }

      // Unify displayed currentPrice as max(selectedAuction.currentPrice, selectedAuction.startingPrice, maxAmount)
      final currentAuction = activeAuction.value;
      final auctionCurrent = currentAuction?.currentPrice ?? 0;
      final auctionStarting = currentAuction?.startingPrice ?? 0;
      final maxBidInt = maxBidAmount.round();

      var unifiedPrice = auctionCurrent;
      if (auctionStarting > unifiedPrice) unifiedPrice = auctionStarting;
      if (maxBidInt > unifiedPrice) unifiedPrice = maxBidInt;

      if (unifiedPrice > 0) {
        currentHighestBid.value = unifiedPrice;
        _updateAuctionPriceInList(
          auctionId,
          unifiedPrice,
          winnerId: highestBid?.bidderId,
          winnerName: highestBid?.bidderName,
        );
      }

      if (highestBid != null && maxBidInt >= unifiedPrice) {
        highestBidderId.value = highestBid.bidderId;
        highestBidderName.value = highestBid.bidderName;
      }
    } catch (e) {
      debugPrint('[LiveBiddingController] Failed to load auction_bids: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Channel Subscriptions Setup
  // ---------------------------------------------------------------------------
  Future<void> _setupPresenceAndChannels() async {
    if (!Hosteday.isInitialized) return;

    // Seed initial state directly from Hosteday.realtime.isConnected
    // in case connect() already completed before entering this screen.
    isConnected.value = Hosteday.realtime.isConnected;
    isConnecting.value = !isConnected.value;
    connectionError.value = Hosteday.realtime.lastError ?? '';

    try {
      // 1. Listen to SDK realtime connection state stream
      _streamSubscriptions.add(
        Hosteday.realtime.onConnectionStateChanged.listen((connected) {
          isConnected.value = connected;
          if (connected) {
            isConnecting.value = false;
            connectionError.value = '';
            _subscribeChannels();
            _addLog(
              title: 'live_bidding_log_radar_connected'.tr,
              description: 'live_bidding_log_connected_desc'.trParams({
                'host': Hosteday.realtime.resolvedHost,
              }),
              channelType: 'Realtime',
              amount: null,
            );
          }
        }),
      );

      // 2. Listen to SDK realtime WebSocket & channel auth errors
      _streamSubscriptions.add(
        Hosteday.realtime.onError.listen((err) {
          connectionError.value = err;
          isConnecting.value = false;
          _addLog(
            title: 'live_bidding_log_connection_err'.tr,
            description: err,
            channelType: 'Error',
            amount: null,
          );
        }),
      );

      // 3. Listen to Auth State Changes (e.g. user signs in while on this screen)
      _streamSubscriptions.add(
        Hosteday.auth.authStateChanges().listen((user) {
          _ensureSelfInBidders();
          if (user != null) {
            connectionError.value = '';
            _isPresenceSubscribed = false;
            _isPrivateSubscribed = false;
            if (isConnected.value) {
              _subscribeChannels();
            }
          }
        }),
      );

      if (!Hosteday.realtime.isConnected) {
        await Hosteday.connectRealtime();
      }

      isConnected.value = Hosteday.realtime.isConnected;
      isConnecting.value = !isConnected.value && connectionError.value.isEmpty;
      await _subscribeChannels();

      if (isConnected.value) {
        _addLog(
          title: 'live_bidding_log_radar_connected'.tr,
          description: 'live_bidding_log_connected_desc'.trParams({
            'host': Hosteday.realtime.resolvedHost,
          }),
          channelType: 'Realtime',
          amount: null,
        );
      }
    } catch (e) {
      connectionError.value = e.toString();
      isConnecting.value = false;
      isConnected.value = Hosteday.realtime.isConnected;
      _addLog(
        title: 'live_bidding_log_connection_err'.tr,
        description: 'live_bidding_log_connection_err_desc'.trParams({
          'err': e.toString(),
        }),
        channelType: 'Error',
        amount: null,
      );
    }
  }

  /// Retries the WebSocket connection and channel subscriptions.
  Future<void> reconnect() async {
    if (!Hosteday.isInitialized) return;
    connectionError.value = '';
    isConnecting.value = true;
    _isPresenceSubscribed = false;
    _isPrivateSubscribed = false;
    _isPublicSubscribed = false;
    try {
      await Hosteday.disconnectRealtime();
      await Hosteday.connectRealtime();
      isConnected.value = Hosteday.realtime.isConnected;
      isConnecting.value = !isConnected.value;
      await _subscribeChannels();
    } catch (e) {
      connectionError.value = e.toString();
      isConnecting.value = false;
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
    final roomChannel = currentRoomChannel;
    if (_isPresenceSubscribed && _subscribedPresenceChannel == roomChannel) {
      return;
    }
    if (!isAuthenticated) {
      return;
    }

    try {
      // Subscribe to per-auction presence channel (`presence-auction.{id}`)
      final channel = await Hosteday.realtime.subscribePresence(roomChannel);
      _subscribedPresenceChannel = roomChannel;
      _isPresenceSubscribed = true;

      // 1. Initial Members List (`pusher:subscription_succeeded`)
      final hereSub = await Hosteday.realtime.listenPresenceMembersList(
        channel: roomChannel,
        onEvent: (event) {
          _handlePresenceHere(event.data);
        },
      );
      _presenceStreamSubscriptions.add(hereSub);

      // 2. Listen for joining members (JOINING)
      final addSub = await Hosteday.realtime.listenPresenceMemberAdded(
        channel: roomChannel,
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
      _presenceStreamSubscriptions.add(addSub);

      // 3. Listen for leaving members (LEAVING)
      final removeSub = await Hosteday.realtime.listenPresenceMemberRemoved(
        channel: roomChannel,
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
      _presenceStreamSubscriptions.add(removeSub);

      // 4. Listen for server-broadcast bid events (`AuctionBidPlaced`)
      final serverBidSub = await Hosteday.realtime.listen(
        channel: roomChannel,
        event: serverBidEventName,
        type: HostedayChannelType.presence,
        onEvent: (event) {
          _handleIncomingWhisperBid(event.data);
        },
      );
      _presenceStreamSubscriptions.add(serverBidSub);

      // 5. Listen for per-auction unified event (`auction.{id}`)
      final roomBidSub = await Hosteday.realtime.listen(
        channel: roomChannel,
        event: roomChannel,
        type: HostedayChannelType.presence,
        onEvent: (event) {
          _handleIncomingWhisperBid(event.data);
        },
      );
      _presenceStreamSubscriptions.add(roomBidSub);

      // 6. Listen for Whisper events (`client-new-bid`) as backup
      final whisperSub = await Hosteday.realtime.listen(
        channel: roomChannel,
        event: whisperEventName,
        type: HostedayChannelType.presence,
        onEvent: (event) {
          _handleIncomingWhisperBid(event.data);
        },
      );
      _presenceStreamSubscriptions.add(whisperSub);

      // 7. Catch-all safety net on the presence channel for any non-pusher:* bid event
      final bindAllSub = channel.bindToAll().listen((rawEvent) {
        final name = rawEvent.name;
        if (name.startsWith('pusher:') || name.startsWith('pusher_internal:')) {
          return;
        }
        _handleIncomingWhisperBid(rawEvent.data);
      });
      _presenceStreamSubscriptions.add(bindAllSub);
    } catch (e) {
      _isPresenceSubscribed = false;
      _subscribedPresenceChannel = null;
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
      final nowUtc = DateTime.now().toUtc();
      final currentAuction = activeAuction.value;
      final roomChannel = currentRoomChannel;
      final bidModel = BidEventModel(
        bidderId: currentUserId,
        bidderName: currentUserName,
        amount: newAmount,
        increment: increment,
        platform: 'flutter',
        timestamp: nowUtc,
      );
      final bidPayload = <String, dynamic>{
        if (currentAuction != null) 'auction_id': currentAuction.id,
        'bidder_id': currentUserId,
        'bidder_name': currentUserName,
        'amount': newAmount,
        'increment': increment,
        'platform': 'flutter',
        'timestamp': nowUtc.toIso8601String(),
      };

      // Record bid key to prevent duplicate local processing from REST + Whisper echo
      _processedBidKeys.add(_bidDedupKey(bidModel));

      // 1. Optimistic local UI update immediately
      _applyBid(
        amount: newAmount,
        bidderName: currentUserName,
        bidderId: currentUserId,
        platformLabel: bidModel.platformLabel,
        isSelf: true,
      );
      if (currentAuction != null) {
        activeAuction.value = currentAuction.copyWith(
          currentPrice: newAmount,
          winnerId: currentUserId,
          winnerName: currentUserName,
        );
        _updateAuctionPriceInList(
          currentAuction.id,
          newAmount,
          winnerId: currentUserId,
          winnerName: currentUserName,
        );
      }

      // 2. Persist bid in `auction_bids` table
      try {
        await Hosteday.client.post(
          auctionBidsPath,
          body: <String, dynamic>{
            if (currentAuction != null) 'auction_id': currentAuction.id,
            'room_id': roomChannel,
            'bidder_id': currentUserId,
            'bidder_name': currentUserName,
            'amount': newAmount,
            'increment': increment,
            'platform': 'flutter',
          },
          withAuth: isAuthenticated,
        );
      } catch (bidPersistError) {
        debugPrint(
          '[LiveBiddingController] POST /api/auction_bids notice: $bidPersistError',
        );
      }

      // 3. Broadcast officially via POST /api/realtime/events/presence (`AuctionBidPlaced`)
      if (isAuthenticated) {
        try {
          await Hosteday.client.publishPresenceEvent(
            channel: roomChannel,
            event: serverBidEventName,
            payload: bidPayload,
          );
        } catch (publishError) {
          debugPrint(
            '[LiveBiddingController] publishPresenceEvent(AuctionBidPlaced) notice: $publishError',
          );
        }
      }

      // 4. Update active auction in `auctions` table (isolated try/catch)
      if (currentAuction != null) {
        try {
          await Hosteday.client.patch(
            auctionsPath,
            id: currentAuction.id,
            body: <String, dynamic>{
              'current_price': newAmount,
              'winner_id': currentUserId,
              'winner_name': currentUserName,
            },
            withAuth: isAuthenticated,
          );
        } catch (auctionPatchError) {
          debugPrint(
            '[LiveBiddingController] PATCH /api/auctions/${currentAuction.id} notice: $auctionPatchError',
          );
        }
      }

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

  Map<String, dynamic>? _extractBidPayload(dynamic rawData) {
    dynamic current = rawData;
    for (var depth = 0; depth < 3; depth++) {
      if (current is String) {
        final trimmed = current.trim();
        if (trimmed.isEmpty) return null;
        try {
          current = jsonDecode(trimmed);
        } catch (_) {
          return null;
        }
      } else if (current is Map) {
        final map = Map<String, dynamic>.from(current);
        if (map.containsKey('payload') && map['payload'] != null) {
          current = map['payload'];
          continue;
        }
        if (!map.containsKey('amount') &&
            map.containsKey('data') &&
            map['data'] != null) {
          current = map['data'];
          continue;
        }
        return map;
      } else {
        return null;
      }
    }
    return current is Map ? Map<String, dynamic>.from(current) : null;
  }

  void _handleIncomingWhisperBid(dynamic rawData) {
    final data = _extractBidPayload(rawData);
    if (data == null || !data.containsKey('amount')) return;

    final currentAuction = activeAuction.value;
    final eventAuctionId = data['auction_id']?.toString().trim();
    if (currentAuction != null &&
        eventAuctionId != null &&
        eventAuctionId.isNotEmpty &&
        eventAuctionId != currentAuction.id.toString()) {
      return;
    }

    final newBid = BidEventModel.fromJson(data);
    final dedupKey = _bidDedupKey(newBid);
    if (_processedBidKeys.contains(dedupKey)) {
      return;
    }

    final incomingAmount = BidEventModel.parseDouble(
      data['amount'],
      fallback: newBid.exactAmount,
    );

    if (incomingAmount > currentHighestBid.value.toDouble()) {
      _processedBidKeys.add(dedupKey);
      final wasSelfHighest = isCurrentHighestBidder;
      final isNewBidFromSelf = newBid.bidderId == currentUserId;

      _applyBid(
        amount: incomingAmount.round(),
        bidderName: newBid.bidderName,
        bidderId: newBid.bidderId,
        platformLabel: newBid.platformLabel,
        isSelf: isNewBidFromSelf,
      );

      if (currentAuction != null) {
        activeAuction.value = currentAuction.copyWith(
          currentPrice: incomingAmount.round(),
          winnerId: newBid.bidderId,
          winnerName: newBid.bidderName,
        );
        _updateAuctionPriceInList(
          currentAuction.id,
          incomingAmount.round(),
          winnerId: newBid.bidderId,
          winnerName: newBid.bidderName,
        );
      }

      // If user was previously the leader and got outbid by someone else
      if (wasSelfHighest && !isNewBidFromSelf) {
        hasOutbidNotice.value = true;
        lastOutbidMessage.value = 'live_bidding_outbid_by_msg'.trParams({
          'name': newBid.bidderName,
          'amount': incomingAmount.round().toString(),
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
    required String platformLabel,
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
      channelType: 'Presence',
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
      final auction = activeAuction.value;
      if (auction != null && auction.endsAt != null) {
        remainingSeconds.value = auction.remainingSecondsFrom(
          DateTime.now().toUtc(),
        );
      } else if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
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
        _subscribedPresenceChannel ?? currentRoomChannel,
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

  String _bidDedupKey(BidEventModel bid) =>
      '${bid.bidderId}_${bid.amount}_${bid.timestamp.toUtc().toIso8601String()}';

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
