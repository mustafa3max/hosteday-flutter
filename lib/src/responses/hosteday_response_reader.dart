import '../exceptions/hosteday_exception.dart';
import 'hosteday_page.dart';

/// Validates the envelopes used by Hosteday resource reads.
class HostedayResponseReader {
  /// Reads a paginated index response without coercing record values.
  static HostedayPage index(Map<String, dynamic> hostedayResponse) {
    final hostedayData = _data(hostedayResponse, 'index');
    final hostedayItems = hostedayData['data'];
    if (hostedayItems is! List ||
        hostedayItems.any((item) => item is! Map<String, dynamic>)) {
      _fail(hostedayResponse, 'index.data.data must be a list of objects');
    }
    for (final key in ['current_page', 'per_page']) {
      final value = hostedayData[key];
      if (value is! int || value < 1) {
        _fail(hostedayResponse, 'index.data.$key must be a positive integer');
      }
    }
    for (final key in ['from', 'to', 'total', 'last_page']) {
      final value = hostedayData[key];
      if (value != null && (value is! int || value < 0)) {
        _fail(hostedayResponse, 'index.data.$key must be an integer or null');
      }
    }
    for (final key in ['next_page_url', 'prev_page_url']) {
      final value = hostedayData[key];
      if (value != null && (value is! String || value.trim().isEmpty)) {
        _fail(
          hostedayResponse,
          'index.data.$key must be a non-empty string or null',
        );
      }
    }
    return HostedayPage(
      items: hostedayItems.cast<Map<String, dynamic>>().toList(),
      currentPage: hostedayData['current_page'] as int,
      perPage: hostedayData['per_page'] as int,
      nextPageUrl: hostedayData['next_page_url'] as String?,
      previousPageUrl: hostedayData['prev_page_url'] as String?,
      from: hostedayData['from'] as int?,
      to: hostedayData['to'] as int?,
      total: hostedayData['total'] as int?,
      lastPage: hostedayData['last_page'] as int?,
    );
  }

  /// Reads the single object returned by show.
  static Map<String, dynamic> show(Map<String, dynamic> hostedayResponse) =>
      _data(hostedayResponse, 'show');

  static Map<String, dynamic> _data(
    Map<String, dynamic> hostedayResponse,
    String operation,
  ) {
    if (hostedayResponse['success'] == false) {
      _fail(hostedayResponse, '$operation operation failed');
    }
    if (hostedayResponse['success'] != true) {
      _fail(hostedayResponse, '$operation.success must be true');
    }
    final hostedayData = hostedayResponse['data'];
    if (hostedayData is! Map<String, dynamic>) {
      _fail(hostedayResponse, '$operation.data must be an object');
    }
    return hostedayData;
  }

  static Never _fail(Map<String, dynamic> hostedayResponse, String detail) {
    final hostedayError = HostedayException.fromResponse(hostedayResponse);
    throw HostedayException(
      'Invalid Hosteday response: $detail. ${hostedayError.message}',
      response: hostedayResponse,
      validationErrors: hostedayError.validationErrors,
      error: FormatException(detail),
    );
  }
}
