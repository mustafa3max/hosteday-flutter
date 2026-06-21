import '../exceptions/hosteday_exception.dart';

/// Represents an authentication-specific HosteDay error.
class HosteDayAuthException extends HosteDayException {
  /// Stable machine-readable error code.
  final String code;

  /// Creates an authentication exception.
  const HosteDayAuthException(
    super.message, {
    required this.code,
    super.statusCode,
    super.error,
  });

  /// Converts a general HosteDay request error into an auth error.
  factory HosteDayAuthException.fromHosteDayException(
    HosteDayException exception,
  ) {
    final rawError = exception.error;

    String? serverCode;

    if (rawError is Map) {
      serverCode =
          rawError['code']?.toString() ?? rawError['error_code']?.toString();
    }

    return HosteDayAuthException(
      exception.message,
      code: serverCode ?? _codeFromStatus(exception.statusCode),
      statusCode: exception.statusCode,
      error: exception.error,
    );
  }

  static String _codeFromStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'invalid-argument';

      case 401:
        return 'invalid-credentials';

      case 403:
        return 'permission-denied';

      case 409:
        return 'email-already-in-use';

      case 422:
        return 'validation-failed';

      default:
        return 'auth-request-failed';
    }
  }

  @override
  String toString() {
    return 'HosteDayAuthException('
        'code: $code, '
        'message: $message, '
        'statusCode: $statusCode, '
        'error: $error'
        ')';
  }
}
