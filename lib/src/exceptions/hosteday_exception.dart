/// Represents an error returned while communicating with HosteDay services.
///
/// This exception can include:
/// - A human-readable [message].
/// - An optional HTTP [statusCode].
/// - Validation errors returned from Laravel-style responses.
/// - The original underlying [error] when available.
class HosteDayException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The HTTP status code associated with the error, when available.
  final int? statusCode;

  /// Field-level validation errors returned by the API.
  ///
  /// Example:
  /// `{ "email": ["The email field is required."] }`
  final Map<String, List<String>> validationErrors;

  /// The decoded response body returned by the API, when available.
  final Map<String, dynamic>? response;

  /// The original error or exception that caused this failure, when available.
  final Object? error;

  /// Creates a HosteDay exception with the provided [message].
  const HosteDayException(
    this.message, {
    this.statusCode,
    this.validationErrors = const <String, List<String>>{},
    this.response,
    this.error,
  });

  /// Creates a [HosteDayException] from a decoded API response.
  factory HosteDayException.fromResponse(
    Map<String, dynamic> response, {
    int? statusCode,
    Object? error,
  }) {
    final message = _extractMessage(response);
    final validationErrors = _extractValidationErrors(response);

    return HosteDayException(
      message,
      statusCode: statusCode,
      validationErrors: validationErrors,
      response: response,
      error: error,
    );
  }

  /// Whether this exception contains field-level validation errors.
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Whether this exception represents a validation failure.
  bool get isValidationError => statusCode == 422;

  /// Whether this exception represents an unauthenticated request.
  bool get isUnauthenticated => statusCode == 401;

  /// Whether this exception represents a forbidden request.
  bool get isForbidden => statusCode == 403;

  /// Whether this exception represents a missing resource.
  bool get isNotFound => statusCode == 404;

  /// Whether this exception represents a server-side error.
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Returns the first validation error for [field], when available.
  String? firstErrorFor(String field) {
    final errors = validationErrors[field];

    if (errors == null || errors.isEmpty) {
      return null;
    }

    return errors.first;
  }

  /// Returns the first validation error from any field, when available.
  String? get firstValidationError {
    for (final errors in validationErrors.values) {
      if (errors.isNotEmpty) {
        return errors.first;
      }
    }

    return null;
  }

  /// Returns the most useful error message for UI display.
  ///
  /// If a validation error exists, it is returned first.
  /// Otherwise, the main exception [message] is returned.
  String get displayMessage {
    return firstValidationError ?? message;
  }

  /// Returns a readable representation of this exception and its details.
  @override
  String toString() {
    final parts = <String>[
      'message: $message',
    ];

    if (statusCode != null) {
      parts.add('statusCode: $statusCode');
    }

    if (validationErrors.isNotEmpty) {
      parts.add('validationErrors: $validationErrors');
    }

    if (error != null) {
      parts.add('error: $error');
    }

    return 'HosteDayException(${parts.join(', ')})';
  }

  static String _extractMessage(Map<String, dynamic> response) {
    final message = response['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final error = response['error'];

    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    return 'HosteDay request failed.';
  }

  static Map<String, List<String>> _extractValidationErrors(
    Map<String, dynamic> response,
  ) {
    final rawErrors = response['errors'];

    if (rawErrors is! Map) {
      return const <String, List<String>>{};
    }

    final result = <String, List<String>>{};

    for (final entry in rawErrors.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is List) {
        result[key] = value.map((item) => item.toString()).toList();
        continue;
      }

      if (value is String) {
        result[key] = <String>[value];
        continue;
      }

      result[key] = <String>[value.toString()];
    }

    return result;
  }
}
