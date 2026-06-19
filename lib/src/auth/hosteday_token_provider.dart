abstract class HosteDayTokenProvider {
  Future<String?> getToken();
}

class StaticHosteDayTokenProvider implements HosteDayTokenProvider {
  final String? token;

  const StaticHosteDayTokenProvider(this.token);

  @override
  Future<String?> getToken() async => token;
}