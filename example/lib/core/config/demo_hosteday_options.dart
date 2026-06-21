/// قيم العرض التجريبي فقط.
///
/// لا تضع مفاتيح أو أسرار الإنتاج داخل تطبيق Flutter منشور للعامة.
abstract final class DemoHosteDayOptions {
  static const String projectDomain = 'enterprise.hosteday.com';

  /// null يعني أن X-Api-Token لن يُرسل تلقائياً.
  static const String? apiToken = null;

  static const String realtimeHost = 'ws3.hosteday.com';
  static const String pusherKey = '7c1b2fzvo8urw7hoktay';
}
