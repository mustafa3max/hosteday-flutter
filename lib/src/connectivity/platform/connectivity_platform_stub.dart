import 'connectivity_platform.dart';

/// Creates the fallback platform connectivity implementation.
ConnectivityPlatform createConnectivityPlatform() => ConnectivityPlatformStub();

/// Fallback platform connectivity implementation.
class ConnectivityPlatformStub implements ConnectivityPlatform {
  @override
  bool get isSupported => false;

  @override
  bool get isOnline => true;

  @override
  void setupListeners({
    required void Function() onOnline,
    required void Function() onOffline,
  }) {}

  @override
  Future<bool> probeHost(String host) async => true;

  @override
  void dispose() {}
}
