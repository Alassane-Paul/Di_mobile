class AppConfig {
  // Base configuration for API & WebSockets.
  // In production, update this with your domain (e.g., 'https://di.yourdomain.com/api')
  static String baseUrl = 'http://localhost:5000/api';
  static String socketUrl = 'http://localhost:5000';
  static String serverUrl = 'http://localhost:5000';

  static void setServerAddress(String hostAndPort, {bool isHttps = false}) {
    final scheme = isHttps ? 'https' : 'http';
    serverUrl = '$scheme://$hostAndPort';
    socketUrl = '$scheme://$hostAndPort';
    baseUrl = '$scheme://$hostAndPort/api';
  }

  static String buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverUrl$cleanPath';
  }
}
