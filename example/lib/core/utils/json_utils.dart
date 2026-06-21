import 'dart:convert';

abstract final class JsonUtils {
  static Map<String, dynamic> decodeObject(String value) {
    if (value.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(value);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const FormatException('Payload يجب أن يكون JSON Object.');
  }

  static String pretty(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
