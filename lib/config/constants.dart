class AppConstants {
  static const String appName = 'DevPocket';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';
  
  // Production URLs (uncomment for production)
  // static const String apiBaseUrl = 'https://api.devpocket.io';
  // static const String wsBaseUrl = 'wss://api.devpocket.io';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // App Configuration
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const int maxRetryAttempts = 3;
  
  // Terminal Configuration
  static const int terminalMaxLines = 10000;
  static const int terminalCols = 80;
  static const int terminalRows = 24;
  
  // WebSocket Configuration
  static const int wsReconnectDelayMs = 2000;
  static const int wsMaxReconnectAttempts = 5;
}