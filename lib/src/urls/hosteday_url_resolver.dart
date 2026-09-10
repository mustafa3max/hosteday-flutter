/// The single URL policy for REST, public pages, and media.
class HostedayUrlResolver {
  final Uri _host;
  final Uri _api;

  /// Creates the shared project URL policy with an optional API override.
  HostedayUrlResolver({required String projectDomain, String? apiBaseUrl})
      : _host = root(projectDomain),
        _api = _apiRoot(apiBaseUrl ?? projectDomain);

  /// Project origin, without a trailing slash or API prefix.
  String get host => _host.origin;

  /// Effective API base URL, without a trailing slash.
  String get apiBaseUrl => _api.toString();

  /// Parses a project domain while preserving an explicit HTTP scheme and port.
  static Uri root(String value) {
    final uri = _httpUri(value);
    if (uri.path.isNotEmpty &&
        uri.path != '/' &&
        uri.path != '/api' &&
        uri.path != '/api/') {
      throw ArgumentError.value(value, 'projectDomain',
          'Use a domain or origin, not a resource path.');
    }
    return Uri.parse(uri.origin);
  }

  static Uri _httpUri(String value) {
    final text = value.trim();
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (text.isEmpty ||
        uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        RegExp(r'\s').hasMatch(text)) {
      throw ArgumentError('A valid HTTP(S) domain or URL is required.');
    }
    return uri;
  }

  static Uri _apiRoot(String value) {
    final uri = _httpUri(value);
    final segments = _segments(uri.path);
    return uri.replace(
        path: '/${segments.isEmpty ? 'api' : segments.join('/')}');
  }

  static void _validateRawPath(String value) {
    final path = value.split('?').first.split('#').first;
    for (final part in path.split('/')) {
      final decoded = Uri.decodeComponent(part);
      if (decoded == '.' || decoded == '..' || decoded.contains('\\')) {
        throw ArgumentError('Path traversal is not supported.');
      }
    }
  }

  static List<String> _segments(String path) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    for (final part in parts) {
      final decoded = Uri.decodeComponent(part);
      if (decoded == '.' ||
          decoded == '..' ||
          decoded.contains('/') ||
          decoded.contains('\\')) {
        throw ArgumentError(
            'Traversal and encoded path separators are not supported.');
      }
    }
    return parts;
  }

  /// Adds the API prefix once. Absolute URLs must belong to the API origin.
  Uri api(String path) {
    _validateRawPath(path);
    final input = Uri.parse(path.trim());
    if (input.hasScheme || input.hasAuthority) {
      if (!['http', 'https'].contains(input.scheme) ||
          input.origin != _api.origin ||
          input.userInfo.isNotEmpty) {
        throw ArgumentError('REST URLs must use the configured API origin.');
      }
    }
    if (input.hasFragment) {
      throw ArgumentError('REST URLs cannot contain fragments.');
    }
    final parts = _segments(input.path);
    final prefix = _segments(_api.path);
    final hasPrefix = parts.length >= prefix.length &&
        List.generate(prefix.length, (i) => parts[i] == prefix[i])
            .every((v) => v);
    if (hasPrefix) {
      parts.removeRange(0, prefix.length);
    } else if (parts.isNotEmpty && parts.first == 'api') {
      parts.removeAt(0);
    }
    return _api.replace(
      path: '/${[...prefix, ...parts].join('/')}',
      query: input.hasQuery ? input.query : null,
    );
  }

  /// Resolves one public page slug without assuming that the page exists.
  String page(String slug) {
    _validateRawPath(slug);
    final uri = Uri.parse(slug.trim());
    final parts = _segments(uri.path);
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        parts.length != 1) {
      throw ArgumentError.value(
          slug, 'slug', 'One non-empty page slug is required.');
    }
    return _host.replace(path: '/${parts.single}').toString();
  }

  /// Resolves public media under `/storage`; leaves full HTTP(S) URLs intact.
  String storage(String path) {
    final text = path.trim();
    final uri = Uri.parse(text);
    if (uri.hasScheme) {
      if (!['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw ArgumentError('Media URLs must use HTTP(S).');
      }
      return text;
    }
    if (uri.hasAuthority || uri.hasQuery || uri.hasFragment) {
      throw ArgumentError('Use a relative file path or a full HTTP(S) URL.');
    }
    _validateRawPath(text);
    final parts = _segments(uri.path);
    if (parts.isEmpty) throw ArgumentError('A file path is required.');
    if (parts.first == 'storage') parts.removeAt(0);
    return _host
        .replace(path: '/${['storage', ...parts].join('/')}')
        .toString();
  }
}
