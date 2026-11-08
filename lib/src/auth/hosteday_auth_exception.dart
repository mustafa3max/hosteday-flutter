import '../exceptions/hosteday_exception.dart';

/// Represents an authentication-specific Hosteday error.
class HostedayAuthException extends HostedayException {
  /// Stable machine-readable error code.
  final String code;

  /// Creates an authentication exception.
  const HostedayAuthException(
    super.message, {
    required this.code,
    super.statusCode,
    super.error,
    super.response,
    super.validationErrors,
  });

  /// Converts a general Hosteday request error into an auth error.
  factory HostedayAuthException.fromHostedayException(
    HostedayException exception,
  ) {
    final rawError =
        exception.response?['error'] ?? exception.response ?? exception.error;

    String? serverCode;

    if (rawError is Map) {
      serverCode =
          rawError['code']?.toString() ?? rawError['error_code']?.toString();
    }

    return HostedayAuthException(
      exception.message,
      code: serverCode ?? _codeFromStatus(exception.statusCode),
      statusCode: exception.statusCode,
      error: exception.error,
      response: exception.response,
      validationErrors: exception.validationErrors,
    );
  }

  /// Legacy factory spelling.
  @Deprecated('Use fromHostedayException instead.')
  factory HostedayAuthException.fromHosteDayException(
          HostedayException exception) =>
      HostedayAuthException.fromHostedayException(exception);

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
    return 'HostedayAuthException('
        'code: $code, '
        'message: $message, '
        'statusCode: $statusCode, '
        'error: $error'
        ')';
  }
}

/// Deprecated spelling of [HostedayAuthException].
@Deprecated('Use HostedayAuthException instead.')
typedef HosteDayAuthException = HostedayAuthException;
