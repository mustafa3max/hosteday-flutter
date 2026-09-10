import 'hosteday_user.dart';

/// Represents an authenticated Hosteday user session.
class HostedaySession {
  /// The authenticated user.
  final HostedayUser user;

  /// Bearer token used by Hosteday HTTP and realtime services.
  final String accessToken;

  /// Optional refresh token supplied by the backend.
  final String? refreshToken;

  /// Usually Bearer.
  final String tokenType;

  /// Token expiry time, when returned by the backend.
  final DateTime? expiresAt;

  /// Creates a Hosteday session.
  const HostedaySession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
  });

  /// Returns whether the session token has expired.
  bool get isExpired {
    final expiry = expiresAt;

    if (expiry == null) {
      return false;
    }

    return expiry.isBefore(DateTime.now().toUtc());
  }

  /// Creates a session from previously stored JSON data.
  factory HostedaySession.fromJson(Map<String, dynamic> json) {
    final userData = _asMap(json['user']);

    if (userData == null) {
      throw const FormatException(
        'Stored Hosteday session does not include user data.',
      );
    }

    final accessToken = _firstText(
      <Map<String, dynamic>>[json],
      const <String>[
        'access_token',
        'accessToken',
        'token',
      ],
    );

    if (accessToken == null) {
      throw const FormatException(
        'Stored Hosteday session does not include an access token.',
      );
    }

    return HostedaySession(
      user: HostedayUser.fromJson(userData),
      accessToken: accessToken,
      refreshToken: _firstText(
        <Map<String, dynamic>>[json],
        const <String>[
          'refresh_token',
          'refreshToken',
        ],
      ),
      tokenType: _firstText(
            <Map<String, dynamic>>[json],
            const <String>[
              'token_type',
              'tokenType',
            ],
          ) ??
          'Bearer',
      expiresAt: _parseDate(json['expires_at'] ?? json['expiresAt']),
    );
  }

  /// Creates a session from common Laravel-style authentication responses.
  ///
  /// Supported token keys:
  /// - access_token
  /// - accessToken
  /// - token
  ///
  /// Supported response shapes:
  /// - { token, user }
  /// - { access_token, user }
  /// - { data: { token, user } }
  /// - { data: { access_token, user } }
  factory HostedaySession.fromAuthResponse(
    Map<String, dynamic> response,
  ) {
    final root = Map<String, dynamic>.from(response);
    final data = _asMap(root['data']);

    final sources = <Map<String, dynamic>>[
      if (data != null) data,
      root,
    ];

    final userData = _asMap(data?['user']) ??
        _asMap(root['user']) ??
        (_looksLikeUser(data) ? data : null) ??
        (_looksLikeUser(root) ? root : null);

    if (userData == null) {
      throw const FormatException(
        'Authentication response does not include user data.',
      );
    }

    final accessToken = _firstText(
      sources,
      const <String>[
        'access_token',
        'accessToken',
        'token',
      ],
    );

    if (accessToken == null) {
      throw const FormatException(
        'Authentication response does not include an access token.',
      );
    }

    final expiresAt = _parseDate(
          _firstValue(
            sources,
            const <String>[
              'expires_at',
              'expiresAt',
            ],
          ),
        ) ??
        _expiresAtFromSeconds(
          _firstValue(
            sources,
            const <String>[
              'expires_in',
              'expiresIn',
            ],
          ),
        );

    return HostedaySession(
      user: HostedayUser.fromJson(userData),
      accessToken: accessToken,
      refreshToken: _firstText(
        sources,
        const <String>[
          'refresh_token',
          'refreshToken',
        ],
      ),
      tokenType: _firstText(
            sources,
            const <String>[
              'token_type',
              'tokenType',
            ],
          ) ??
          'Bearer',
      expiresAt: expiresAt,
    );
  }

  /// Converts this session into a persistable JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }

  /// Returns a copy of this session with selected values replaced.
  HostedaySession copyWith({
    HostedayUser? user,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
  }) {
    return HostedaySession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static bool _looksLikeUser(Map<String, dynamic>? value) {
    if (value == null) {
      return false;
    }

    return value.containsKey('id') ||
        value.containsKey('user_id') ||
        value.containsKey('uuid');
  }

  static String? _firstText(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    final value = _firstValue(sources, keys);

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static dynamic _firstValue(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        if (source.containsKey(key) && source[key] != null) {
          return source[key];
        }
      }
    }

    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static DateTime? _expiresAtFromSeconds(dynamic value) {
    if (value == null) {
      return null;
    }

    final seconds =
        value is num ? value.toInt() : int.tryParse(value.toString());

    if (seconds == null || seconds <= 0) {
      return null;
    }

    return DateTime.now().toUtc().add(
          Duration(seconds: seconds),
        );
  }
}

/// Deprecated spelling of [HostedaySession].
@Deprecated('Use HostedaySession instead.')
typedef HosteDaySession = HostedaySession;
