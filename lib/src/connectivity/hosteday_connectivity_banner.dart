import 'dart:async';

import 'package:flutter/material.dart';

import '../hosteday.dart';
import 'hosteday_connectivity.dart';

/// Position where the connectivity banner is anchored on screen.
enum HostedayBannerPosition {
  /// Displays the banner at the top of the screen.
  top,

  /// Displays the banner at the bottom of the screen.
  bottom,
}

/// An automated overlay banner widget that monitors Hosteday connectivity and
/// displays a non-intrusive alert when the connection is lost or restored.
///
/// Designed to sit directly in `MaterialApp.builder` or `GetMaterialApp.builder`
/// above the Navigator:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => HostedayConnectivityBanner(
///     child: child ?? const SizedBox.shrink(),
///   ),
/// );
/// ```
class HostedayConnectivityBanner extends StatefulWidget {
  /// The underlying app content (Navigator) to wrap.
  final Widget child;

  /// Optional connectivity instance. Defaults to [Hosteday.connectivity] if initialized.
  final HostedayConnectivity? connectivity;

  /// Custom message shown when the connection is lost.
  final String? offlineMessage;

  /// Custom message shown temporarily when connection is restored.
  final String? restoredMessage;

  /// How long the green "connection restored" banner remains visible.
  final Duration restoredDuration;

  /// Position of the banner: [HostedayBannerPosition.top] or [HostedayBannerPosition.bottom].
  final HostedayBannerPosition position;

  /// Optional custom builder for full styling control.
  final Widget Function(
    BuildContext context,
    bool isOnline,
    bool isRestored,
    Widget child,
  )? builder;

  const HostedayConnectivityBanner({
    super.key,
    required this.child,
    this.connectivity,
    this.offlineMessage,
    this.restoredMessage,
    this.restoredDuration = const Duration(seconds: 3),
    this.position = HostedayBannerPosition.top,
    this.builder,
  });

  @override
  State<HostedayConnectivityBanner> createState() =>
      _HostedayConnectivityBannerState();
}

class _HostedayConnectivityBannerState
    extends State<HostedayConnectivityBanner> {
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  bool _showRestored = false;
  Timer? _restoredTimer;

  HostedayConnectivity? get _effectiveConnectivity {
    if (widget.connectivity != null) {
      return widget.connectivity;
    }
    if (Hosteday.isInitialized) {
      return Hosteday.connectivity;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(HostedayConnectivityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectivity != oldWidget.connectivity) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    final conn = _effectiveConnectivity;
    if (conn != null) {
      _isOnline = conn.isConnected;
      _subscription = conn.onStatusChange.listen((isOnline) {
        if (!mounted) return;
        if (!_isOnline && isOnline) {
          // Transitioned from offline to online
          _restoredTimer?.cancel();
          setState(() {
            _isOnline = true;
            _showRestored = true;
          });
          _restoredTimer = Timer(widget.restoredDuration, () {
            if (mounted) {
              setState(() {
                _showRestored = false;
              });
            }
          });
        } else if (!isOnline) {
          _restoredTimer?.cancel();
          setState(() {
            _isOnline = false;
            _showRestored = false;
          });
        } else {
          setState(() {
            _isOnline = isOnline;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, _isOnline, _showRestored, widget.child);
    }

    final isVisible = !_isOnline || _showRestored;
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    final text = !_isOnline
        ? (widget.offlineMessage ??
            (isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection'))
        : (widget.restoredMessage ??
            (isArabic
                ? 'تمت استعادة الاتصال بالإنترنت'
                : 'Connection restored'));

    final backgroundColor = !_isOnline
        ? const Color(0xFFDC2626) // Red-600
        : const Color(0xFF16A34A); // Green-600

    final icon = !_isOnline ? Icons.wifi_off_rounded : Icons.wifi_rounded;

    final bannerContent = Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                fontFamilyFallback: ['Roboto', 'sans-serif'],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          if (isVisible)
            Positioned(
              top: widget.position == HostedayBannerPosition.top ? 0 : null,
              bottom:
                  widget.position == HostedayBannerPosition.bottom ? 0 : null,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: Offset.zero,
                child: Material(
                  type: MaterialType.transparency,
                  child: SafeArea(
                    top: widget.position == HostedayBannerPosition.top,
                    bottom: widget.position == HostedayBannerPosition.bottom,
                    left: false,
                    right: false,
                    child: bannerContent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
