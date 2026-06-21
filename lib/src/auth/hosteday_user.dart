/// Represents the currently authenticated HosteDay user.
class HosteDayUser {
  /// The stable unique identifier of the user.
  final String id;

  /// The user's email address, when available.
  final String? email;

  /// The display name of the user, when available.
  final String? displayName;

  /// Whether the user's email has been verified.
  final bool emailVerified;

  /// The profile image URL, when available.
  final String? photoUrl;

  /// The original user data returned by the HosteDay API.
  final Map<String, dynamic> data;

  /// Creates a HosteDay user.
  HosteDayUser({
    required this.id,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.photoUrl,
    Map<String, dynamic>? data,
  }) : data = Map<String, dynamic>.unmodifiable(
          data ?? <String, dynamic>{},
        );

  /// Alias for [displayName].
  String? get name => displayName;

  /// Creates a user from an API response map.
  factory HosteDayUser.fromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    final id = _firstText(
      normalized,
      const <String>[
        'id',
        'user_id',
        'uuid',
      ],
    );

    if (id == null) {
      throw const FormatException(
        'HosteDay user response does not include an id.',
      );
    }

    return HosteDayUser(
      id: id,
      email: _firstText(
        normalized,
        const <String>[
          'email',
        ],
      ),
      displayName: _firstText(
        normalized,
        const <String>[
          'name',
          'display_name',
          'displayName',
        ],
      ),
      emailVerified: _toBool(
        normalized['email_verified'] ?? normalized['emailVerified'],
      ),
      photoUrl: _firstText(
        normalized,
        const <String>[
          'avatar_url',
          'avatar',
          'photo_url',
          'photoUrl',
        ],
      ),
      data: normalized,
    );
  }

  /// Converts this user into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...data,
      'id': id,
      'email': email,
      'name': displayName,
      'email_verified': emailVerified,
      'avatar_url': photoUrl,
    };
  }

  /// Returns a copy of this user with selected values replaced.
  HosteDayUser copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? emailVerified,
    String? photoUrl,
    Map<String, dynamic>? data,
  }) {
    return HosteDayUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      data: data ?? this.data,
    );
  }

  static String? _firstText(
    Map<String, dynamic> values,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = values[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }
}
