/// Helper methods for reading common API response shapes.
///
/// Different Laravel APIs may return lists as:
/// - `{ "data": [...] }`
/// - `{ "data": { "data": [...] } }` for paginated responses
/// - `{ "posts": [...] }`
///
/// This reader keeps the example tolerant and focused on HosteDay usage rather
/// than a single backend response format.
class ApiResponseReader {
  const ApiResponseReader._();

  static List<Map<String, dynamic>> readList(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response['posts'] is List) {
      return (response['posts'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  static Map<String, dynamic>? readObject(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map) {
      final nestedPost = data['post'];

      if (nestedPost is Map) {
        return Map<String, dynamic>.from(nestedPost);
      }

      return Map<String, dynamic>.from(data);
    }

    final post = response['post'];

    if (post is Map) {
      return Map<String, dynamic>.from(post);
    }

    return null;
  }

  static String? firstText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }
}
