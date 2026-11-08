import 'hosteday_url_resolver.dart';

/// Public page links. This builds URLs; it does not fetch or create pages.
class HostedayStaticPages {
  final HostedayUrlResolver _urls;

  /// Uses the same URL resolver as the REST client.
  const HostedayStaticPages(this._urls);

  /// Example: `client.staticPages['/info/']` resolves to `$host/info`.
  String operator [](String slug) => _urls.page(slug);
}
