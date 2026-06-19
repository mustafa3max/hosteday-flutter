class HosteDayException implements Exception {
  final String message;
  final int? statusCode;
  final Object? error;

  const HosteDayException(
      this.message, {
        this.statusCode,
        this.error,
      });

  @override
  String toString() {
    return 'HosteDayException(message: $message, statusCode: $statusCode, error: $error)';
  }
}