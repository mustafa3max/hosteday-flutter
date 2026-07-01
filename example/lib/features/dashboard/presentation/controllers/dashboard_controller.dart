import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/models/action_feedback.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../core/utils/realtime_utils.dart';
import '../../data/models/realtime_log.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required HosteDayUser user})
    : _user = user,
      nameController = TextEditingController(text: user.displayName ?? ''),
      emailController = TextEditingController(text: user.email ?? ''),
      channelController = TextEditingController(text: 'tenant.chat.room.1'),
      eventController = TextEditingController(text: 'message.sent'),
      payloadController = TextEditingController(
        text: const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'message': 'Welcome from HosteDay Flutter',
        }),
      );

  HosteDayUser _user;
  HosteDayUser get user => _user;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController channelController;
  final TextEditingController eventController;
  final TextEditingController payloadController;

  HosteDayChannelType _channelType = HosteDayChannelType.public;
  HosteDayChannelType get channelType => _channelType;

  bool _isApiLoading = false;
  bool get isApiLoading => _isApiLoading;

  bool _isRealtimeLoading = false;
  bool get isRealtimeLoading => _isRealtimeLoading;

  bool get isBusy => _isApiLoading || _isRealtimeLoading;

  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  bool _isRealtimeSubscribed = false;
  bool get isRealtimeSubscribed => _isRealtimeSubscribed;

  String? _activeChannel;
  HosteDayChannelType? _activeChannelType;

  StreamSubscription<dynamic>? _eventSubscription;
  StreamSubscription<dynamic>? _memberAddedSubscription;
  StreamSubscription<dynamic>? _memberRemovedSubscription;

  String? _apiResult;
  String? get apiResult => _apiResult;

  bool _apiResultIsError = false;
  bool get apiResultIsError => _apiResultIsError;

  final List<RealtimeLog> _realtimeLogs = <RealtimeLog>[];
  List<RealtimeLog> get realtimeLogs =>
      List<RealtimeLog>.unmodifiable(_realtimeLogs);

  bool _isDisposed = false;

  void changeChannelType(HosteDayChannelType? value) {
    if (value == null || isBusy) {
      return;
    }

    _channelType = value;
    notifyListeners();
  }

  void clearApiResult() {
    if (isBusy) {
      return;
    }

    _apiResult = null;
    _apiResultIsError = false;
    notifyListeners();
  }

  Future<ActionFeedback?> reloadUser() {
    return _runApiAction(
      loadingMessage: 'جاري إعادة جلب بيانات المستخدم...',
      action: () async {
        final user = await HosteDay.auth.reload();
        _setCurrentUser(user);

        return <String, dynamic>{'user': user.toJson()};
      },
    );
  }

  Future<ActionFeedback?> updateProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty && email.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل اسماً أو بريداً إلكترونياً لتحديثه.',
        isError: true,
      );
    }

    return _runApiAction(
      loadingMessage: 'جاري تحديث الملف الشخصي...',
      action: () async {
        final user = await HosteDay.auth.updateProfile(<String, dynamic>{
          if (name.isNotEmpty) 'name': name,
          if (email.isNotEmpty) 'email': email,
        });

        _setCurrentUser(user);

        return <String, dynamic>{'user': user.toJson()};
      },
    );
  }

  Future<ActionFeedback?> getPosts() {
    return _runApiAction(
      loadingMessage: 'جاري جلب المنشورات...',
      action: () => HosteDay.client.get('/api/posts', withAuth: true),
    );
  }

  Future<ActionFeedback?> sendEmailVerification() {
    return _runApiAction(
      loadingMessage: 'جاري إرسال رابط التحقق...',
      action: () async {
        await HosteDay.auth.sendEmailVerification();

        return <String, dynamic>{'status': 'verification-email-requested'};
      },
    );
  }

  Future<ActionFeedback?> logout() async {
    if (_isApiLoading) {
      return null;
    }

    _setApiLoading(true);

    try {
      await HosteDay.auth.signOut();

      // لا تحتاج إلى disconnect هنا.
      // HosteDayAuth ينظف الجلسة ويستدعي فصل Realtime تلقائياً.
      _isRealtimeConnected = false;
      _isRealtimeSubscribed = false;
      _activeChannel = null;
      _activeChannelType = null;
      _notify();
      return null;
    } on HosteDayAuthException catch (error) {
      return ActionFeedback(
        message:
            'تم حذف الجلسة المحلية، لكن Logout في السيرفر فشل: ${error.message}',
        isError: true,
      );
    } on HosteDayException catch (error) {
      return ActionFeedback(
        message:
            'تم حذف الجلسة المحلية، لكن Logout في السيرفر فشل: ${error.message}',
        isError: true,
      );
    } catch (error) {
      return ActionFeedback(
        message: 'حدث خطأ أثناء تسجيل الخروج: $error',
        isError: true,
      );
    } finally {
      _setApiLoading(false);
    }
  }

  Future<ActionFeedback?> connectRealtime() async {
    if (_isRealtimeLoading) {
      return null;
    }

    _setRealtimeLoading(true);

    try {
      await HosteDay.connectRealtime();

      _isRealtimeConnected = true;
      _addRealtimeLog(
        title: 'Realtime connected',
        details: HosteDay.config.realtimeUrl,
      );
      _notify();
      return null;
    } on HosteDayException catch (error) {
      _addRealtimeLog(
        title: 'Connection error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(
        message: 'فشل الاتصال بـ Realtime: ${error.message}',
        isError: true,
      );
    } catch (error) {
      _addRealtimeLog(
        title: 'Connection error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(
        message: 'حدث خطأ أثناء اتصال Realtime: $error',
        isError: true,
      );
    } finally {
      _setRealtimeLoading(false);
    }
  }

  Future<ActionFeedback?> subscribeRealtime() async {
    final channel = channelController.text.trim();
    final event = eventController.text.trim();

    if (channel.isEmpty || event.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل اسم القناة واسم الحدث.',
        isError: true,
      );
    }

    if (_isRealtimeLoading) {
      return null;
    }

    _setRealtimeLoading(true);

    try {
      await HosteDay.connectRealtime();
      await _cancelRealtimeListeners(unsubscribeActiveChannel: true);

      final normalizedChannel = RealtimeUtils.normalizedChannelName(
        channel,
        _channelType,
      );

      _eventSubscription = await HosteDay.client.realtime.listen(
        channel: channel,
        event: event,
        type: _channelType,
        onEvent: _onRealtimeEvent,
      );

      if (_channelType == HosteDayChannelType.presence) {
        _memberAddedSubscription = await HosteDay.client.realtime
            .listenPresenceMemberAdded(
              channel: channel,
              onEvent: _onMemberAdded,
            );

        _memberRemovedSubscription = await HosteDay.client.realtime
            .listenPresenceMemberRemoved(
              channel: channel,
              onEvent: _onMemberRemoved,
            );
      }

      _isRealtimeConnected = true;
      _isRealtimeSubscribed = true;
      _activeChannel = channel;
      _activeChannelType = _channelType;

      _addRealtimeLog(
        title: 'Subscribed',
        details: JsonUtils.pretty(<String, dynamic>{
          'channel': normalizedChannel,
          'event': event,
          'type': RealtimeUtils.channelTypeLabel(_channelType),
        }),
      );
      _notify();
      return null;
    } on HosteDayException catch (error) {
      _addRealtimeLog(
        title: 'Subscribe error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(
        message: 'فشل الاشتراك: ${error.message}',
        isError: true,
      );
    } catch (error) {
      _addRealtimeLog(
        title: 'Subscribe error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(message: 'فشل الاشتراك: $error', isError: true);
    } finally {
      _setRealtimeLoading(false);
    }
  }

  Future<ActionFeedback?> unsubscribeRealtime() async {
    if (_isRealtimeLoading) {
      return null;
    }

    _setRealtimeLoading(true);

    try {
      final channel = _activeChannel;
      final type = _activeChannelType;

      await _cancelRealtimeListeners(unsubscribeActiveChannel: true);

      _isRealtimeSubscribed = false;
      _activeChannel = null;
      _activeChannelType = null;

      if (channel != null && type != null) {
        _addRealtimeLog(
          title: 'Unsubscribed',
          details: RealtimeUtils.normalizedChannelName(channel, type),
        );
      }

      _notify();
      return null;
    } catch (error) {
      return ActionFeedback(
        message: 'فشل إلغاء الاشتراك: $error',
        isError: true,
      );
    } finally {
      _setRealtimeLoading(false);
    }
  }

  Future<ActionFeedback?> publishRealtimeEvent() async {
    final rawChannel = channelController.text.trim();
    final event = eventController.text.trim();

    if (rawChannel.isEmpty || event.isEmpty) {
      return const ActionFeedback(
        message: 'أدخل اسم القناة واسم الحدث.',
        isError: true,
      );
    }

    late final Map<String, dynamic> payload;

    try {
      payload = JsonUtils.decodeObject(payloadController.text);
    } on FormatException catch (error) {
      return ActionFeedback(
        message: 'Payload غير صالح: ${error.message}',
        isError: true,
      );
    }

    if (_isRealtimeLoading) {
      return null;
    }

    _setRealtimeLoading(true);

    try {
      final channel = RealtimeUtils.normalizedChannelName(
        rawChannel,
        _channelType,
      );

      late final Map<String, dynamic> response;

      switch (_channelType) {
        case HosteDayChannelType.public:
          response = await HosteDay.client.publishPublicEvent(
            channel: channel,
            event: event,
            payload: payload,
          );
          break;
        case HosteDayChannelType.private:
          response = await HosteDay.client.publishPrivateEvent(
            channel: channel,
            event: event,
            payload: payload,
          );
          break;
        case HosteDayChannelType.presence:
          response = await HosteDay.client.publishPresenceEvent(
            channel: channel,
            event: event,
            payload: payload,
          );
          break;
        case HosteDayChannelType.privateEncrypted:
          throw UnsupportedError(
            'إرسال private encrypted events يحتاج endpoint مخصص في السيرفر لتشفير Payload.',
          );
      }

      _addRealtimeLog(
        title: 'Published event',
        details: JsonUtils.pretty(<String, dynamic>{
          'channel': channel,
          'event': event,
          'payload': payload,
          'response': response,
        }),
      );
      _notify();
      return null;
    } on HosteDayException catch (error) {
      _addRealtimeLog(
        title: 'Publish error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(
        message: 'فشل إرسال الحدث: ${error.message}',
        isError: true,
      );
    } catch (error) {
      _addRealtimeLog(
        title: 'Publish error',
        details: error.toString(),
        isError: true,
      );

      return ActionFeedback(message: 'فشل إرسال الحدث: $error', isError: true);
    } finally {
      _setRealtimeLoading(false);
    }
  }

  Future<ActionFeedback?> disconnectRealtime() async {
    if (_isRealtimeLoading) {
      return null;
    }

    _setRealtimeLoading(true);

    try {
      await _cancelRealtimeListeners(unsubscribeActiveChannel: false);
      await HosteDay.client.realtime.disconnect();

      _isRealtimeConnected = false;
      _isRealtimeSubscribed = false;
      _activeChannel = null;
      _activeChannelType = null;

      _addRealtimeLog(
        title: 'Realtime disconnected',
        details: 'The realtime connection was closed.',
      );
      _notify();
      return null;
    } catch (error) {
      return ActionFeedback(
        message: 'فشل قطع اتصال Realtime: $error',
        isError: true,
      );
    } finally {
      _setRealtimeLoading(false);
    }
  }

  Future<ActionFeedback?> _runApiAction({
    required String loadingMessage,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    if (_isApiLoading) {
      return null;
    }

    _isApiLoading = true;
    _apiResult = loadingMessage;
    _apiResultIsError = false;
    _notify();

    try {
      final response = await action();

      _apiResult = JsonUtils.pretty(response);
      _apiResultIsError = false;
      _notify();
      return null;
    } on HosteDayAuthException catch (error) {
      _apiResult = JsonUtils.pretty(<String, dynamic>{
        'code': error.code,
        'message': error.message,
        'statusCode': error.statusCode,
      });
      _apiResultIsError = true;
      _notify();
      return null;
    } on HosteDayException catch (error) {
      _apiResult = JsonUtils.pretty(<String, dynamic>{
        'message': error.message,
        'statusCode': error.statusCode,
        'error': error.error?.toString(),
      });
      _apiResultIsError = true;
      _notify();
      return null;
    } catch (error) {
      _apiResult = error.toString();
      _apiResultIsError = true;
      _notify();
      return null;
    } finally {
      _setApiLoading(false);
    }
  }

  void _setCurrentUser(HosteDayUser user) {
    _user = user;
    nameController.text = user.displayName ?? '';
    emailController.text = user.email ?? '';
  }

  Future<void> _cancelRealtimeListeners({
    required bool unsubscribeActiveChannel,
  }) async {
    await _eventSubscription?.cancel();
    await _memberAddedSubscription?.cancel();
    await _memberRemovedSubscription?.cancel();

    _eventSubscription = null;
    _memberAddedSubscription = null;
    _memberRemovedSubscription = null;

    if (!unsubscribeActiveChannel) {
      return;
    }

    final channel = _activeChannel;
    final type = _activeChannelType;

    if (channel == null || type == null) {
      return;
    }

    await HosteDay.client.realtime.unsubscribe(channel, type: type);
  }

  void _onRealtimeEvent(HosteDayRealtimeEvent event) {
    _addRealtimeLog(
      title: 'Received ${event.name}',
      details: JsonUtils.pretty(<String, dynamic>{
        'channel': event.channelName,
        'event': event.name,
        'message': event.message,
        'user': event.user,
        'payload': event.payload,
      }),
    );
  }

  void _onMemberAdded(HosteDayRealtimeEvent event) {
    _addRealtimeLog(
      title: 'Presence member joined',
      details: JsonUtils.pretty(<String, dynamic>{
        'channel': event.channelName,
        'member': event.payload,
      }),
    );
  }

  void _onMemberRemoved(HosteDayRealtimeEvent event) {
    _addRealtimeLog(
      title: 'Presence member left',
      details: JsonUtils.pretty(<String, dynamic>{
        'channel': event.channelName,
        'member': event.payload,
      }),
    );
  }

  void _addRealtimeLog({
    required String title,
    required String details,
    bool isError = false,
  }) {
    _realtimeLogs.insert(
      0,
      RealtimeLog(
        title: title,
        details: details,
        createdAt: DateTime.now(),
        isError: isError,
      ),
    );

    if (_realtimeLogs.length > 40) {
      _realtimeLogs.removeLast();
    }

    _notify();
  }

  void _setApiLoading(bool value) {
    _isApiLoading = value;
    _notify();
  }

  void _setRealtimeLoading(bool value) {
    _isRealtimeLoading = value;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    unawaited(_eventSubscription?.cancel());
    unawaited(_memberAddedSubscription?.cancel());
    unawaited(_memberRemovedSubscription?.cancel());

    nameController.dispose();
    emailController.dispose();
    channelController.dispose();
    eventController.dispose();
    payloadController.dispose();

    super.dispose();
  }
}
