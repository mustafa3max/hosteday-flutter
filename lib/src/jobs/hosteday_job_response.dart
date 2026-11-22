import 'dart:collection';

/// Represents the response returned by Hosteday background job operations.
///
/// Implements [Map] via [MapMixin] for seamless backward compatibility
/// with callers expecting raw [Map<String, dynamic>].
class HostedayJobResponse with MapMixin<String, dynamic> {
  final Map<String, dynamic> _raw;

  /// The unique identifier of the background job.
  final String? jobId;

  /// The execution status of the job (e.g. queued, processing, completed, failed).
  final String? status;

  /// Whether the job operation was dispatched or executed successfully.
  final bool success;

  /// An optional message returned by the server.
  final String? message;

  /// The payload associated with the job.
  final Map<String, dynamic>? payload;

  /// Additional data returned with the job response.
  final dynamic data;

  HostedayJobResponse({
    required Map<String, dynamic> raw,
    this.jobId,
    this.status,
    this.success = true,
    this.message,
    this.payload,
    this.data,
  }) : _raw = Map<String, dynamic>.unmodifiable(raw);

  /// Creates a [HostedayJobResponse] from a JSON-compatible map.
  factory HostedayJobResponse.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] == true ||
        (json['status'] != null && json['status'] != 'failed');

    final rawPayload = json['payload'];
    final payloadMap = rawPayload is Map<String, dynamic>
        ? rawPayload
        : (rawPayload is Map ? Map<String, dynamic>.from(rawPayload) : null);

    final rawId = json['job_id'] ?? json['id'] ?? json['jobId'];
    final rawStatus = json['status']?.toString();
    final rawMessage = json['message']?.toString();

    return HostedayJobResponse(
      raw: json,
      jobId: rawId?.toString(),
      status: rawStatus,
      success: isSuccess,
      message: rawMessage,
      payload: payloadMap,
      data: json['data'],
    );
  }

  // ---------------------------------------------------------------------------
  // MapMixin implementation for 100% backward compatibility
  // ---------------------------------------------------------------------------

  @override
  dynamic operator [](Object? key) => _raw[key];

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('HostedayJobResponse is unmodifiable.');
  }

  @override
  void clear() {
    throw UnsupportedError('HostedayJobResponse is unmodifiable.');
  }

  @override
  Iterable<String> get keys => _raw.keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('HostedayJobResponse is unmodifiable.');
  }

  /// Converts the response to a JSON-compatible map.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_raw);

  @override
  String toString() {
    return 'HostedayJobResponse('
        'jobId: $jobId, '
        'status: $status, '
        'success: $success, '
        'message: $message'
        ')';
  }
}

/// Backward-compatible alias for [HostedayJobResponse].
typedef HosteDayJobResponse = HostedayJobResponse;
