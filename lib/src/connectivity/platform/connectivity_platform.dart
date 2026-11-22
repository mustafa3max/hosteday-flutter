import 'connectivity_platform_stub.dart'
    if (dart.library.html) 'connectivity_platform_web.dart'
    if (dart.library.io) 'connectivity_platform_io.dart';

/// Abstract platform-specific connectivity provider.
abstract class ConnectivityPlatform {
  /// Default singleton instance for the current platform.
  static final ConnectivityPlatform instance = createConnectivityPlatform();

  /// Whether platform-specific connectivity events are supported.
  bool get isSupported;

  /// Immediate synchronous connectivity state if reported by the platform.
  bool get isOnline;

  /// Sets up listeners for platform connectivity change events.
  void setupListeners({
    required void Function() onOnline,
    required void Function() onOffline,
  });

  /// Probes DNS / host reachability on platform.
  Future<bool> probeHost(String host);

  /// Releases platform resources.
  void dispose();
}
