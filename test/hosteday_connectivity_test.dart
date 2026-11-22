import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter/src/connectivity/platform/connectivity_platform.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockConnectivityPlatform implements ConnectivityPlatform {
  bool _online;
  void Function()? onOnlineCallback;
  void Function()? onOfflineCallback;

  MockConnectivityPlatform({bool initialOnline = true})
      : _online = initialOnline;

  @override
  bool get isSupported => true;

  @override
  bool get isOnline => _online;

  @override
  void setupListeners({
    required void Function() onOnline,
    required void Function() onOffline,
  }) {
    onOnlineCallback = onOnline;
    onOfflineCallback = onOffline;
  }

  void triggerOffline() {
    _online = false;
    onOfflineCallback?.call();
  }

  void triggerOnline() {
    _online = true;
    onOnlineCallback?.call();
  }

  @override
  Future<bool> probeHost(String host) async => _online;

  @override
  void dispose() {}
}

class MockInternetConnection implements InternetConnection {
  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();
  bool _hasAccess;

  MockInternetConnection({bool initialAccess = true})
      : _hasAccess = initialAccess;

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  @override
  Future<bool> get hasInternetAccess async => _hasAccess;

  @override
  Future<InternetStatus> get internetStatus async =>
      _hasAccess ? InternetStatus.connected : InternetStatus.disconnected;

  void emit(InternetStatus status) {
    _hasAccess = status == InternetStatus.connected;
    _controller.add(status);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Hosteday.dispose);

  const testConfig = HostedayConfig(
    baseUrl: 'https://test.hosteday.com',
  );

  group('HostedayConnectivity Core Service', () {
    test('initial state defaults to isConnected = true', () {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
      );
      addTearDown(connectivity.dispose);

      expect(connectivity.isConnected, isTrue);
    });

    test(
        'reportFailure and reportSuccess transition state and emit on onStatusChange',
        () async {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
      );
      addTearDown(connectivity.dispose);

      final transitions = <bool>[];
      final subscription = connectivity.onStatusChange.listen(transitions.add);
      addTearDown(subscription.cancel);

      // Report failure (offline)
      connectivity.reportFailure();
      expect(connectivity.isConnected, isFalse);

      // Duplicate failure should not emit duplicate event
      connectivity.reportFailure();
      expect(connectivity.isConnected, isFalse);

      // Report success (online)
      connectivity.reportSuccess();
      expect(connectivity.isConnected, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(transitions, equals([false, true]));
    });

    test('manual updateStatus emits changes correctly', () async {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
      );
      addTearDown(connectivity.dispose);

      final transitions = <bool>[];
      final subscription = connectivity.onStatusChange.listen(transitions.add);
      addTearDown(subscription.cancel);

      connectivity.updateStatus(false);
      expect(connectivity.isConnected, isFalse);

      connectivity.updateStatus(true);
      expect(connectivity.isConnected, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(transitions, equals([false, true]));
    });

    test('checkNow returns true when server responds successfully', () async {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
        initialConnected: false,
      );
      addTearDown(connectivity.dispose);

      final isOnline = await connectivity.checkNow();
      expect(isOnline, isTrue);
      expect(connectivity.isConnected, isTrue);
    });

    test('checkNow returns false when network request fails', () async {
      final mockChecker = MockInternetConnection(initialAccess: false);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
        initialConnected: true,
      );
      addTearDown(connectivity.dispose);

      final isOnline = await connectivity.checkNow();
      expect(isOnline, isFalse);
      expect(connectivity.isConnected, isFalse);
    });

    test('instantly detects offline state when platform fires onOffline event',
        () async {
      final mockPlatform = MockConnectivityPlatform(initialOnline: true);
      final mockChecker = MockInternetConnection(initialAccess: true);

      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
        platform: mockPlatform,
      );
      addTearDown(connectivity.dispose);

      expect(connectivity.isConnected, isTrue);

      // Trigger browser/OS offline event
      mockPlatform.triggerOffline();
      expect(connectivity.isConnected, isFalse);
    });

    test('initiates verification when platform fires onOnline event', () async {
      final mockPlatform = MockConnectivityPlatform(initialOnline: false);
      final mockChecker = MockInternetConnection(initialAccess: true);

      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
        platform: mockPlatform,
      );
      addTearDown(connectivity.dispose);

      expect(connectivity.isConnected, isFalse);

      mockPlatform.triggerOnline();
      await Future<void>.delayed(Duration.zero);
      expect(connectivity.isConnected, isTrue);
    });

    test('initializes as offline if platform isOnline is false at startup', () {
      final mockPlatform = MockConnectivityPlatform(initialOnline: false);
      final mockChecker = MockInternetConnection(initialAccess: true);

      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
        platform: mockPlatform,
      );
      addTearDown(connectivity.dispose);

      expect(connectivity.isConnected, isFalse);
    });

    test('reacts to InternetConnection onStatusChange stream events', () async {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
      );
      addTearDown(connectivity.dispose);

      final transitions = <bool>[];
      final subscription = connectivity.onStatusChange.listen(transitions.add);
      addTearDown(subscription.cancel);

      mockChecker.emit(InternetStatus.disconnected);
      await Future<void>.delayed(Duration.zero);
      expect(connectivity.isConnected, isFalse);

      mockChecker.emit(InternetStatus.connected);
      await Future<void>.delayed(Duration.zero);
      expect(connectivity.isConnected, isTrue);

      expect(transitions, equals([false, true]));
    });
  });

  group('HostedayHttpClient Passive Connectivity Detection', () {
    test('reports online status when an HTTP request succeeds', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"success": true}', 200);
      });

      final mockChecker = MockInternetConnection(initialAccess: true);
      final client = await Hosteday.initializeApp(
        config: testConfig,
        internetConnection: mockChecker,
      );

      client.connectivity.updateStatus(false);
      expect(Hosteday.isOnline, isFalse);

      // Sending a request should passively report success and flip back to online
      final httpClient = HostedayHttpClient(
        config: testConfig,
        client: mockClient,
        onNetworkResult: client.connectivity.updateStatus,
      );

      await httpClient.get('/test-endpoint');
      expect(Hosteday.isOnline, isTrue);
      expect(client.connectivity.isConnected, isTrue);
    });

    test(
        'reports offline status when an HTTP request throws network ClientException',
        () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable');
      });

      final mockChecker = MockInternetConnection(initialAccess: true);
      final client = await Hosteday.initializeApp(
        config: testConfig,
        internetConnection: mockChecker,
      );

      expect(Hosteday.isOnline, isTrue);

      final httpClient = HostedayHttpClient(
        config: testConfig,
        client: mockClient,
        onNetworkResult: client.connectivity.updateStatus,
      );

      try {
        await httpClient.get('/test-endpoint');
      } catch (_) {}

      expect(Hosteday.isOnline, isFalse);
      expect(Hosteday.connectivity.isConnected, isFalse);
    });
  });

  group('HostedayConnectivityBanner Widget', () {
    testWidgets('renders child and reacts to connectivity state changes',
        (tester) async {
      final mockChecker = MockInternetConnection(initialAccess: true);
      final connectivity = HostedayConnectivity(
        config: testConfig,
        checker: mockChecker,
      );
      addTearDown(connectivity.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostedayConnectivityBanner(
              connectivity: connectivity,
              offlineMessage: 'Offline Alert',
              restoredMessage: 'Restored Alert',
              child: const Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      // Child is rendered and offline alert is initially not visible
      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Offline Alert'), findsNothing);

      // Switch to offline
      connectivity.updateStatus(false);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Offline Alert'), findsOneWidget);

      // Switch back to online (should display restored notice)
      connectivity.updateStatus(true);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Restored Alert'), findsOneWidget);

      // After duration expires, restored notice disappears
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Restored Alert'), findsNothing);
      expect(find.text('Main Content'), findsOneWidget);
    });
  });
}
