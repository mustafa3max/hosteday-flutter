class RealtimeLog {
  const RealtimeLog({
    required this.title,
    required this.details,
    required this.createdAt,
    required this.isError,
  });

  final String title;
  final String details;
  final DateTime createdAt;
  final bool isError;
}
