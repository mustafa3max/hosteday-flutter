/// One server-provided page of Hosteday records.
class HostedayPage {
  /// Records, with their original JSON field values.
  final List<Map<String, dynamic>> items;

  /// Current page number reported by the server.
  final int currentPage;

  /// Page size reported by the server.
  final int perPage;

  /// Server-provided next link; informational only, never fetched automatically.
  final String? nextPageUrl;

  /// Server-provided previous link; informational only.
  final String? previousPageUrl;

  /// First record position, or null for an empty page.
  final int? from;

  /// Last record position, or null for an empty page.
  final int? to;

  /// Total record count, only when supplied by the server.
  final int? total;

  /// Last page number, only when supplied by the server.
  final int? lastPage;

  /// Creates a page from server metadata and records.
  const HostedayPage({
    required this.items,
    required this.currentPage,
    required this.perPage,
    this.nextPageUrl,
    this.previousPageUrl,
    this.from,
    this.to,
    this.total,
    this.lastPage,
  });

  /// Whether the server supplied a next-page link.
  bool get hasNextPage => nextPageUrl != null;

  /// Whether the server supplied a previous-page link.
  bool get hasPreviousPage => previousPageUrl != null;
}
