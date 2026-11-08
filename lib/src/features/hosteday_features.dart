import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Represents feature flags and entitlements for a Hosteday application.
class HostedayFeatures {
  final Map<String, bool> _features;

  /// Default active features when no flags are configured.
  static const Map<String, bool> defaultFeatures = {
    'push_notifications': true,
    'realtime_websockets': true,
    'database_management': true,
  };

  /// Creates a [HostedayFeatures] instance with the provided feature flags.
  const HostedayFeatures([Map<String, bool>? features])
      : _features = features ?? defaultFeatures;

  /// Creates a [HostedayFeatures] instance from a JSON or string-keyed map.
  factory HostedayFeatures.fromMap(Map<String, dynamic> map) {
    final parsed = <String, bool>{};
    map.forEach((key, value) {
      if (value is bool) {
        parsed[key] = value;
      } else if (value is num) {
        parsed[key] = value != 0;
      } else if (value is String) {
        final lower = value.trim().toLowerCase();
        parsed[key] = lower == 'true' || lower == '1';
      }
    });
    return HostedayFeatures(parsed);
  }

  /// Creates a [HostedayFeatures] instance from a decoded JSON object.
  factory HostedayFeatures.fromJson(Map<String, dynamic> json) =>
      HostedayFeatures.fromMap(json);

  /// Checks if a given feature key is enabled.
  ///
  /// Returns [defaultValue] if the key is not explicitly set.
  bool isEnabled(String key, {bool defaultValue = true}) {
    return _features[key] ?? defaultValue;
  }

  /// Whether push notifications are enabled and entitled for the current plan.
  bool get isNotificationsEnabled => isEnabled('push_notifications');

  /// Whether realtime WebSockets are enabled and entitled for the current plan.
  bool get isRealtimeEnabled => isEnabled('realtime_websockets');

  /// Whether database management is enabled and entitled for the current plan.
  bool get isDatabaseEnabled => isEnabled('database_management');

  /// Returns an unmodifiable map of all registered feature flags.
  Map<String, bool> toMap() => Map.unmodifiable(_features);

  /// Attempts to load features from local file or Flutter asset bundle.
  static Future<HostedayFeatures> loadFromAssetOrFile({
    String assetPath = 'assets/config/hosteday_features.json',
    String filePath = 'lib/hosteday_features.json',
    AssetBundle? bundle,
  }) async {
    // 1. Try local file (CLI / unit tests / local environment)
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return HostedayFeatures.fromMap(decoded);
        }
      }
    } catch (_) {
      // Ignore and fallback to bundle/default
    }

    // 2. Try asset bundle (Flutter runtime)
    try {
      final b = bundle ?? rootBundle;
      final raw = await b.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return HostedayFeatures.fromMap(decoded);
      }
    } catch (_) {
      // Fallback
    }

    return const HostedayFeatures();
  }

  @override
  String toString() => 'HostedayFeatures($_features)';
}
