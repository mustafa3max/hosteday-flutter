/// Represents an error returned while communicating with HosteDay services.
///
/// This exception can include a human-readable [message], an optional HTTP
/// [statusCode], and the original underlying [error] when available.
class HosteDayException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The HTTP status code associated with the error, when available.
  final int? statusCode;

  /// The original error or exception that caused this failure, when available.
  final Object? error;

  /// Creates a HosteDay exception with the provided [message].
  ///
  /// The optional [statusCode] identifies the related HTTP response status,
  /// while [error] can preserve the original underlying failure.
  const HosteDayException(this.message, {this.statusCode, this.error});

  /// Returns a readable representation of this exception and its details.
  @override
  String toString() {
    return 'HosteDayException(message: $message, statusCode: $statusCode, error: $error)';
  }
}
