import 'dart:async';

import '../auth/hosteday_token_provider.dart';
import '../config/hosteday_config.dart';
import '../exceptions/hosteday_exception.dart';
import '../http/hosteday_http_client.dart';

/// Manages Hosteday smart background jobs, queues, and task dispatching.
class HostedayJobsClient {
  /// The configuration containing jobs settings and endpoint paths.
  final HostedayConfig config;

  /// The HTTP client used to interact with Hosteday API.
  final HostedayHttpClient http;

  /// Provider for authenticated user access tokens.
  final HostedayTokenProvider? tokenProvider;

  bool _disposed = false;

  /// Creates a jobs client with the supplied [config] and [http] client.
  HostedayJobsClient({
    required this.config,
    required this.http,
    this.tokenProvider,
  });

  /// Whether background jobs features are enabled in [config].
  bool get isEnabled => config.jobsEnabled;

  /// Dispatches a background job to the Hosteday queue.
  Future<Map<String, dynamic>> dispatch({
    required String name,
    Map<String, dynamic>? payload,
    int? delaySeconds,
    bool withAuth = true,
  }) async {
    _ensureNotDisposed();

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const HostedayException('A valid job name is required.');
    }

    final body = <String, dynamic>{
      'job': cleanName,
      if (payload != null) 'payload': payload,
      if (delaySeconds != null) 'delay_seconds': delaySeconds,
    };

    final response = await http.post(
      config.jobsPath,
      body: body,
      withAuth: withAuth,
    );

    return response;
  }

  /// Retrieves the execution status or details of a queued job.
  Future<Map<String, dynamic>> getStatus(
    String jobId, {
    bool withAuth = true,
  }) async {
    _ensureNotDisposed();

    final cleanId = jobId.trim();
    if (cleanId.isEmpty) {
      throw const HostedayException('A valid job ID is required.');
    }

    final response = await http.get(
      '${config.jobsPath}/$cleanId',
      withAuth: withAuth,
    );

    return response;
  }

  /// Lists scheduled or completed background jobs.
  Future<Map<String, dynamic>> listJobs({
    int? page,
    int? perPage,
    String? status,
    bool withAuth = true,
  }) async {
    _ensureNotDisposed();

    final queryParams = <String, String>{
      if (page != null) 'page': '$page',
      if (perPage != null) 'per_page': '$perPage',
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final uri = Uri(
      path: config.jobsPath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri.toString(),
      withAuth: withAuth,
    );

    return response;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const HostedayException('HostedayJobsClient is disposed.');
    }
  }

  /// Releases resources held by the jobs client.
  Future<void> dispose() async {
    _disposed = true;
  }
}

