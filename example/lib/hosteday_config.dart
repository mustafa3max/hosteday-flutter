// HosteDay Official Configuration Template
// Automatically populated when running:
// curl -fsSL https://dash.hosteday.com/cli/setup.sh | bash -s -- --project=your-app --token="your-token"
class HosteDayConfig {
  static const String appName = 'your-project';
  static const String slug = 'your-project';
  static const String baseUrl = 'https://your-project.hosteday.com';
  static const String environmentId = '';

  // Features
  static const bool pushNotificationsEnabled = false;
  static const bool realtimeWebsocketsEnabled = true;

  // Firebase Configuration
  static const String? firebaseProjectId = null;

  // WebSockets (Reverb) Configuration
  static const String wsHost = 'ws.hosteday.com';
  static const int wsPort = 443;
  static const String wsScheme = 'https';
  static const String wsKey = '';
  static const String wsChannel = '';

  // Core API Endpoints
  static const String deviceRegisterEndpoint = '/api/notifications/devices/register';
  static const String deviceUnregisterEndpoint = '/api/notifications/devices/unregister';
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String userEndpoint = '/api/user';
}
