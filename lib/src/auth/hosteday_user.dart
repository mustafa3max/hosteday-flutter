/// Represents the currently authenticated HosteDay user.
class HosteDayUser {
  static const Object _undefined = Object();

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

  /// User creation date, when returned by the API.
  final DateTime? createdAt;

  /// User last update date, when returned by the API.
  final DateTime? updatedAt;

  /// The original user data returned by the HosteDay API.
  final Map<String, dynamic> data;

  /// Creates a HosteDay user.
  HosteDayUser({
    required this.id,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? data,
  }) : data = Map<String, dynamic>.unmodifiable(
          data ?? <String, dynamic>{},
        );

  /// Alias for [displayName].
  String? get name => displayName;

  /// Alias for [photoUrl].
  String? get avatarUrl => photoUrl;

  /// Whether this user has an email address.
  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  /// Whether this user has a display name.
  bool get hasDisplayName {
    return displayName != null && displayName!.trim().isNotEmpty;
  }

  /// Whether this user has a profile image URL.
  bool get hasPhotoUrl => photoUrl != null && photoUrl!.trim().isNotEmpty;

  /// Reads a value from the original user data.
  dynamic operator [](String key) {
    return data[key];
  }

  /// Whether the original user data contains [key].
  bool containsKey(String key) {
    return data.containsKey(key);
  }

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
          'full_name',
          'fullName',
        ],
      ),
      emailVerified: _emailVerified(normalized),
      photoUrl: _firstText(
        normalized,
        const <String>[
          'avatar_url',
          'avatarUrl',
          'avatar',
          'photo_url',
          'photoUrl',
          'image',
          'image_url',
          'imageUrl',
        ],
      ),
      createdAt: _firstDateTime(
        normalized,
        const <String>[
          'created_at',
          'createdAt',
        ],
      ),
      updatedAt: _firstDateTime(
        normalized,
        const <String>[
          'updated_at',
          'updatedAt',
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
      if (email != null) 'email': email,
      if (displayName != null) 'name': displayName,
      'email_verified': emailVerified,
      if (emailVerified && data['email_verified_at'] == null)
        'email_verified_at': data['email_verified_at'],
      if (photoUrl != null) 'avatar_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Returns a copy of this user with selected values replaced.
  ///
  /// Nullable fields can be cleared by explicitly passing `null`.
  ///
  /// Example:
  /// ```dart
  /// final updated = user.copyWith(photoUrl: null);
  /// ```
  HosteDayUser copyWith({
    String? id,
    Object? email = _undefined,
    Object? displayName = _undefined,
    bool? emailVerified,
    Object? photoUrl = _undefined,
    Object? createdAt = _undefined,
    Object? updatedAt = _undefined,
    Map<String, dynamic>? data,
  }) {
    return HosteDayUser(
      id: id ?? this.id,
      email: email == _undefined ? this.email : email as String?,
      displayName:
          displayName == _undefined ? this.displayName : displayName as String?,
      emailVerified: emailVerified ?? this.emailVerified,
      photoUrl: photoUrl == _undefined ? this.photoUrl : photoUrl as String?,
      createdAt:
          createdAt == _undefined ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _undefined ? this.updatedAt : updatedAt as DateTime?,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'HosteDayUser('
        'id: $id, '
        'email: $email, '
        'displayName: $displayName, '
        'emailVerified: $emailVerified, '
        'photoUrl: $photoUrl'
        ')';
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

  static DateTime? _firstDateTime(
    Map<String, dynamic> values,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = values[key];

      final date = _toDateTime(value);

      if (date != null) {
        return date;
      }
    }

    return null;
  }

  static bool _emailVerified(Map<String, dynamic> values) {
    final directValue = values['email_verified'] ?? values['emailVerified'];

    if (_toBool(directValue)) {
      return true;
    }

    final verifiedAt = values['email_verified_at'] ?? values['emailVerifiedAt'];

    if (verifiedAt == null) {
      return false;
    }

    if (verifiedAt is String) {
      return verifiedAt.trim().isNotEmpty;
    }

    return true;
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

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return null;
      }

      return DateTime.tryParse(text);
    }

    return null;
  }
}
