import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'connectivity_platform.dart';

/// Creates the Web platform connectivity implementation.
ConnectivityPlatform createConnectivityPlatform() => ConnectivityPlatformWeb();

/// Web platform connectivity implementation using modern browser events (package:web).
class ConnectivityPlatformWeb implements ConnectivityPlatform {
  JSFunction? _onlineListener;
  JSFunction? _offlineListener;

  @override
  bool get isSupported => true;

  @override
  bool get isOnline => web.window.navigator.onLine;

  @override
  void setupListeners({
    required void Function() onOnline,
    required void Function() onOffline,
  }) {
    dispose();

    _onlineListener = ((web.Event _) {
      onOnline();
    }).toJS;

    _offlineListener = ((web.Event _) {
      onOffline();
    }).toJS;

    web.window.addEventListener('online', _onlineListener!);
    web.window.addEventListener('offline', _offlineListener!);
  }

  @override
  Future<bool> probeHost(String host) async {
    return web.window.navigator.onLine;
  }

  @override
  void dispose() {
    if (_onlineListener != null) {
      web.window.removeEventListener('online', _onlineListener!);
      _onlineListener = null;
    }
    if (_offlineListener != null) {
      web.window.removeEventListener('offline', _offlineListener!);
      _offlineListener = null;
    }
  }
}
