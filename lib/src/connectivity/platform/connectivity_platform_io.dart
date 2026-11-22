import 'dart:io';

import 'connectivity_platform.dart';

/// Creates the IO (Mobile / Desktop) platform connectivity implementation.
ConnectivityPlatform createConnectivityPlatform() => ConnectivityPlatformIo();

/// IO platform connectivity implementation using DNS and socket checks.
class ConnectivityPlatformIo implements ConnectivityPlatform {
  @override
  bool get isSupported => true;

  @override
  bool get isOnline => true;

  @override
  void setupListeners({
    required void Function() onOnline,
    required void Function() onOffline,
  }) {}

  @override
  Future<bool> probeHost(String host) async {
    try {
      final uri = Uri.tryParse(host);
      final cleanHost = (uri != null && uri.host.isNotEmpty) ? uri.host : host;
      final result = await InternetAddress.lookup(cleanHost).timeout(
        const Duration(seconds: 2),
      );
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {}
}
