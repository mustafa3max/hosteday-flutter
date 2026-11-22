import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../config/hosteday_config.dart';
import 'platform/connectivity_platform.dart';

/// Manages internet and Hosteday service connectivity monitoring.
///
/// Powered by an isolated instance of [InternetConnection] from
/// `internet_connection_checker_plus` along with instant platform/browser
/// event listeners and passive HTTP response detection:
///
/// 1. **Immediate Browser & Platform Detection:** Listens directly to platform events
///    (`window.onOffline` / `window.onOnline` on web) to instantly detect disconnection
///    without waiting for an active probe or API call.
/// 2. **Standard Active Verification:** Uses [InternetConnection] to verify real internet
///    access across all platforms (Web, Android, iOS, Windows, macOS, Linux).
/// 3. **Passive Detection:** Automatically updates status when HTTP requests succeed
///    via [reportSuccess] or encounter network errors via [reportFailure].
/// 4. **Isolated Instance:** Avoids global Singleton collisions with the host application.
class HostedayConnectivity {
  /// Configuration holding base URL and project connection settings.
  final HostedayConfig config;

  final InternetConnection _checker;
  final ConnectivityPlatform _platform;

  bool _isConnected = true;
  bool _disposed = false;
  StreamSubscription<InternetStatus>? _checkerSubscription;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  /// Creates a [HostedayConnectivity] instance.
  ///
  /// Uses an isolated [InternetConnection] configured with the app's [config.baseUrl]
  /// and high-reliability default endpoints.
  HostedayConnectivity({
    required this.config,
    InternetConnection? checker,
    ConnectivityPlatform? platform,
    Duration checkInterval = const Duration(seconds: 4),
    Duration probeTimeout = const Duration(seconds: 3),
    bool initialConnected = true,
  })  : _platform = platform ?? ConnectivityPlatform.instance,
        _checker = checker ??
            InternetConnection.createInstance(
              checkInterval: checkInterval,
              customCheckOptions: [
                if (config.baseUrl.isNotEmpty)
                  InternetCheckOption(
                    uri: Uri.parse(config.baseUrl),
                    timeout: probeTimeout,
                    headers: config.defaultHeaders,
                  ),
              ],
              useDefaultOptions: true,
            ) {
    // Initial state considers platform state (e.g. navigator.onLine on web)
    _isConnected = initialConnected && _platform.isOnline;

    _initListeners();
  }

  /// Returns whether the device currently has connectivity to Hosteday services.
  bool get isConnected => _isConnected;

  /// Broadcast stream emitting connectivity status changes (`true` for online, `false` for offline).
  Stream<bool> get onStatusChange => _statusController.stream;

  /// The underlying [InternetConnection] instance used for checking.
  InternetConnection get internetConnection => _checker;

  void _initListeners() {
    // 1. Immediate platform/browser events
    _platform.setupListeners(
      onOnline: () {
        if (_disposed) return;
        checkNow();
      },
      onOffline: () {
        if (_disposed) return;
        reportFailure('Platform reported offline');
      },
    );

    // 2. Underlying internet_connection_checker_plus stream
    _checkerSubscription = _checker.onStatusChange.listen((status) {
      if (_disposed) return;
      final online = status == InternetStatus.connected;
      _updateStatus(online);
    });
  }

  /// Passively reports a successful network response from `HostedayHttpClient`.
  ///
  /// Flips status to `true` if previously offline.
  void reportSuccess() {
    if (_disposed) return;
    if (!_isConnected) {
      _updateStatus(true);
    }
  }

  /// Passively reports a network failure from `HostedayHttpClient` or platform.
  ///
  /// Flips status to `false`.
  void reportFailure([Object? error]) {
    if (_disposed) return;
    if (_isConnected) {
      _updateStatus(false);
    }
  }

  /// Manually updates the connectivity status.
  void updateStatus(bool isOnline) {
    if (_disposed) return;
    _updateStatus(isOnline);
  }

  /// Runs an immediate active probe to determine if the server / internet is reachable.
  Future<bool> checkNow() async {
    if (_disposed) return _isConnected;

    if (!_platform.isOnline) {
      updateStatus(false);
      return false;
    }

    try {
      final online = await _checker.hasInternetAccess;
      updateStatus(online);
      return online;
    } catch (_) {
      updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool newStatus) {
    if (_isConnected != newStatus) {
      _isConnected = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  /// Releases resources held by the connectivity service.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _checkerSubscription?.cancel();
    _checkerSubscription = null;
    _platform.dispose();
    await _checker.dispose();
    await _statusController.close();
  }
}
