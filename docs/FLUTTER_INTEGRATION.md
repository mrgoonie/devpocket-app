# DevPocket Flutter Integration Guide

This guide provides detailed instructions for integrating the DevPocket API and WebSocket connections into Flutter applications.

## Table of Contents

1. [Setup and Dependencies](#setup-and-dependencies)
2. [Project Structure](#project-structure)
3. [Authentication Service](#authentication-service)
4. [API Service](#api-service)
5. [WebSocket Service](#websocket-service)
6. [State Management](#state-management)
7. [UI Components](#ui-components)
8. [Complete Example App](#complete-example-app)

## Setup and Dependencies

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP and API
  dio: ^5.4.0
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # WebSocket
  web_socket_channel: ^2.4.0
  
  # State Management
  provider: ^6.1.1
  flutter_riverpod: ^2.4.9
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Google Sign In
  google_sign_in: ^6.1.5
  
  # Terminal UI
  xterm: ^3.5.0
  
  # Utilities
  equatable: ^2.0.5
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  retrofit_generator: ^8.0.6
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.1
```

## Project Structure

```
lib/
├── main.dart
├── config/
│   └── constants.dart
├── models/
│   ├── user.dart
│   ├── environment.dart
│   ├── auth_response.dart
│   └── error_response.dart
├── services/
│   ├── auth_service.dart
│   ├── api_service.dart
│   ├── websocket_service.dart
│   ├── terminal_websocket_service.dart
│   ├── logs_websocket_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── environment_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── environments_screen.dart
│   └── terminal_screen.dart
├── widgets/
│   ├── environment_card.dart
│   ├── loading_indicator.dart
│   └── websocket_debug_widget.dart
└── utils/
    └── websocket_tester.dart
```

## Authentication Service

### Models

**lib/models/user.dart:**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final bool isActive;
  final bool isVerified;
  final String subscriptionPlan;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.subscriptionPlan,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**lib/models/auth_response.dart:**
```dart
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  
  @JsonKey(name: 'token_type')
  final String tokenType;
  
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
```

### Storage Service

**lib/services/storage_service.dart:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### Auth Service Implementation

**lib/services/auth_service.dart:**
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../config/constants.dart';
import 'storage_service.dart';

part 'auth_service.g.dart';

@RestApi(baseUrl: Constants.apiBaseUrl)
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST('/api/v1/auth/register')
  Future<AuthResponse> register(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/login')
  Future<AuthResponse> login(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/refresh')
  Future<AuthResponse> refreshToken(@Body() Map<String, dynamic> body);

  @GET('/api/v1/auth/me')
  Future<User> getProfile();

  @POST('/api/v1/auth/logout')
  Future<void> logout();
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          final dio = Dio();
          final response = await dio.post(
            '${Constants.apiBaseUrl}/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          
          final authResponse = AuthResponse.fromJson(response.data);
          await StorageService.saveTokens(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
          );
          
          // Retry original request
          err.requestOptions.headers['Authorization'] = 
              'Bearer ${authResponse.accessToken}';
          final cloneReq = await dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );
          
          return handler.resolve(cloneReq);
        } catch (e) {
          // Refresh failed, logout user
          await StorageService.clearAll();
        }
      }
    }
    super.onError(err, handler);
  }
}
```

## API Service

### Environment Models

**lib/models/environment.dart:**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'environment.g.dart';

@JsonSerializable()
class Environment {
  final String id;
  final String name;
  final String template;
  final String status;
  final Resources resources;
  @JsonKey(name: 'external_url')
  final String? externalUrl;
  @JsonKey(name: 'web_port')
  final int? webPort;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_accessed')
  final DateTime? lastAccessed;
  @JsonKey(name: 'cpu_usage')
  final double? cpuUsage;
  @JsonKey(name: 'memory_usage')
  final double? memoryUsage;
  @JsonKey(name: 'storage_usage')
  final double? storageUsage;

  Environment({
    required this.id,
    required this.name,
    required this.template,
    required this.status,
    required this.resources,
    this.externalUrl,
    this.webPort,
    required this.createdAt,
    this.lastAccessed,
    this.cpuUsage,
    this.memoryUsage,
    this.storageUsage,
  });

  factory Environment.fromJson(Map<String, dynamic> json) => 
      _$EnvironmentFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentToJson(this);
}

@JsonSerializable()
class Resources {
  final String cpu;
  final String memory;
  final String storage;

  Resources({
    required this.cpu,
    required this.memory,
    required this.storage,
  });

  factory Resources.fromJson(Map<String, dynamic> json) => 
      _$ResourcesFromJson(json);
  Map<String, dynamic> toJson() => _$ResourcesToJson(this);
}

@JsonSerializable()
class CreateEnvironmentRequest {
  final String name;
  final String template;
  final Resources? resources;
  @JsonKey(name: 'environment_variables')
  final Map<String, String>? environmentVariables;

  CreateEnvironmentRequest({
    required this.name,
    required this.template,
    this.resources,
    this.environmentVariables,
  });

  factory CreateEnvironmentRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateEnvironmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateEnvironmentRequestToJson(this);
}
```

### API Service Implementation

**lib/services/api_service.dart:**
```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/environment.dart';
import '../config/constants.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: Constants.apiBaseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET('/api/v1/environments')
  Future<List<Environment>> getEnvironments();

  @POST('/api/v1/environments')
  Future<Environment> createEnvironment(@Body() CreateEnvironmentRequest request);

  @GET('/api/v1/environments/{id}')
  Future<Environment> getEnvironment(@Path('id') String id);

  @PUT('/api/v1/environments/{id}')
  Future<Environment> updateEnvironment(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/v1/environments/{id}')
  Future<void> deleteEnvironment(@Path('id') String id);

  @POST('/api/v1/environments/{id}/start')
  Future<void> startEnvironment(@Path('id') String id);

  @POST('/api/v1/environments/{id}/stop')
  Future<void> stopEnvironment(@Path('id') String id);

  @GET('/api/v1/environments/{id}/metrics')
  Future<Map<String, dynamic>> getEnvironmentMetrics(@Path('id') String id);
}
```

## WebSocket Service

**lib/services/websocket_service.dart:**
```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants.dart';
import 'storage_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String environmentId;
  
  final _outputController = StreamController<String>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  
  Stream<String> get output => _outputController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;
  Stream<WebSocketMessage> get messages => _messageController.stream;
  
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration pingInterval = Duration(seconds: 30);
  
  WebSocketService({required this.environmentId});

  Future<void> connect() async {
    try {
      _connectionController.add(ConnectionStatus.connecting);
      
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No auth token');
      
      final uri = Uri.parse(
        '${Constants.wsBaseUrl}/api/v1/ws/terminal/$environmentId?token=$token'
      );
      
      _channel = WebSocketChannel.connect(uri);
      _connectionController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      
      // Start ping timer for keepalive
      _startPingTimer();
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      _connectionController.add(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final msgType = data['type'] as String?;
      
      final wsMessage = WebSocketMessage(
        type: msgType ?? 'unknown',
        data: data['data'],
        timestamp: DateTime.now(),
        rawMessage: data,
      );
      
      _messageController.add(wsMessage);
      
      switch (msgType) {
        case 'output':
          _outputController.add(data['data'] ?? '');
          break;
        case 'welcome':
          // Handle welcome message with environment info
          print('Connected to environment: ${data['environment']?['name']}');
          break;
        case 'error':
          print('Server error: ${data['message']}');
          break;
        case 'pong':
          // Keepalive response
          break;
        case 'log':
          // Handle log messages for log streaming
          print('Log: ${data['message']}');
          break;
        default:
          print('Unknown message type: $msgType');
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _connectionController.add(ConnectionStatus.error);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _handleDone() {
    print('WebSocket connection closed');
    _connectionController.add(ConnectionStatus.disconnected);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts);
    _reconnectAttempts++;
    
    print('Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      if (_channel != null) {
        sendPing();
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void sendCommand(String command) {
    if (_channel != null) {
      final message = json.encode({
        'type': 'input',
        'data': command,
      });
      _channel!.sink.add(message);
    }
  }

  void resize(int cols, int rows) {
    if (_channel != null) {
      final message = json.encode({
        'type': 'resize',
        'cols': cols,
        'rows': rows,
      });
      _channel!.sink.add(message);
    }
  }

  void sendPing() {
    if (_channel != null) {
      final message = json.encode({'type': 'ping'});
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _channel?.sink.close(status.goingAway);
    _outputController.close();
    _connectionController.close();
    _messageController.close();
  }

  bool get isConnected => 
      _channel != null && _connectionController.hasListener;
}

// WebSocket message model
class WebSocketMessage {
  final String type;
  final dynamic data;
  final DateTime timestamp;
  final Map<String, dynamic> rawMessage;

  WebSocketMessage({
    required this.type,
    this.data,
    required this.timestamp,
    required this.rawMessage,
  });
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}
```

### Enhanced Terminal WebSocket Service

**lib/services/terminal_websocket_service.dart:**
```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants.dart';
import 'storage_service.dart';

class TerminalWebSocketService {
  WebSocketChannel? _channel;
  final String environmentId;
  
  final _terminalOutputController = StreamController<TerminalOutput>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _environmentInfoController = StreamController<EnvironmentInfo>.broadcast();
  
  Stream<TerminalOutput> get terminalOutput => _terminalOutputController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;
  Stream<EnvironmentInfo> get environmentInfo => _environmentInfoController.stream;
  
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  
  TerminalWebSocketService({required this.environmentId});

  Future<void> connect() async {
    try {
      _connectionController.add(ConnectionStatus.connecting);
      
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No auth token');
      
      final uri = Uri.parse(
        '${Constants.wsBaseUrl}/api/v1/ws/terminal/$environmentId?token=$token'
      );
      
      _channel = WebSocketChannel.connect(uri);
      _connectionController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      
      _startPingTimer();
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      _connectionController.add(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final msgType = data['type'] as String?;
      
      switch (msgType) {
        case 'output':
          _terminalOutputController.add(TerminalOutput(
            data: data['data'] ?? '',
            timestamp: DateTime.now(),
          ));
          break;
          
        case 'welcome':
          final envData = data['environment'];
          if (envData != null) {
            _environmentInfoController.add(EnvironmentInfo(
              id: envData['id'],
              name: envData['name'],
              template: envData['template'],
              status: envData['status'],
              message: data['message'],
            ));
          }
          break;
          
        case 'error':
          _terminalOutputController.add(TerminalOutput(
            data: 'Error: ${data['message']}\n',
            timestamp: DateTime.now(),
            isError: true,
          ));
          break;
          
        case 'pong':
          // Keepalive response - connection is healthy
          break;
      }
    } catch (e) {
      print('Error parsing terminal message: $e');
    }
  }

  void _handleError(error) {
    _connectionController.add(ConnectionStatus.error);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _handleDone() {
    _connectionController.add(ConnectionStatus.disconnected);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= 5) return;
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts);
    _reconnectAttempts++;
    
    _reconnectTimer = Timer(delay, connect);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendPing();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void sendCommand(String command) {
    if (_channel != null) {
      final message = json.encode({
        'type': 'input',
        'data': command,
      });
      _channel!.sink.add(message);
    }
  }

  void resizeTerminal(int cols, int rows) {
    if (_channel != null) {
      final message = json.encode({
        'type': 'resize',
        'cols': cols,
        'rows': rows,
      });
      _channel!.sink.add(message);
    }
  }

  void sendPing() {
    if (_channel != null) {
      final message = json.encode({'type': 'ping'});
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _channel?.sink.close(status.goingAway);
    _terminalOutputController.close();
    _connectionController.close();
    _environmentInfoController.close();
  }
}

// Terminal-specific models
class TerminalOutput {
  final String data;
  final DateTime timestamp;
  final bool isError;

  TerminalOutput({
    required this.data,
    required this.timestamp,
    this.isError = false,
  });
}

class EnvironmentInfo {
  final String id;
  final String name;
  final String template;
  final String status;
  final String? message;

  EnvironmentInfo({
    required this.id,
    required this.name,
    required this.template,
    required this.status,
    this.message,
  });
}
```

### Log Streaming WebSocket Service

**lib/services/logs_websocket_service.dart:**
```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants.dart';
import 'storage_service.dart';

class LogsWebSocketService {
  WebSocketChannel? _channel;
  final String environmentId;
  final bool follow;
  
  final _logsController = StreamController<LogEntry>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  
  Stream<LogEntry> get logs => _logsController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;
  
  LogsWebSocketService({
    required this.environmentId,
    this.follow = true,
  });

  Future<void> connect() async {
    try {
      _connectionController.add(ConnectionStatus.connecting);
      
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No auth token');
      
      final uri = Uri.parse(
        '${Constants.wsBaseUrl}/api/v1/ws/logs/$environmentId?token=$token&follow=$follow'
      );
      
      _channel = WebSocketChannel.connect(uri);
      _connectionController.add(ConnectionStatus.connected);
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      _connectionController.add(ConnectionStatus.error);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      
      if (data['type'] == 'log') {
        _logsController.add(LogEntry(
          timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
          level: _parseLogLevel(data['level']),
          message: data['message'] ?? '',
        ));
      }
    } catch (e) {
      print('Error parsing log message: $e');
    }
  }

  LogLevel _parseLogLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  void _handleError(error) {
    _connectionController.add(ConnectionStatus.error);
  }

  void _handleDone() {
    _connectionController.add(ConnectionStatus.disconnected);
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _logsController.close();
    _connectionController.close();
  }
}

// Log models
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
```

## State Management

### Auth Provider

**lib/providers/auth_provider.dart:**
```dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final Dio _dio;
  late final AuthService _authService;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  AuthProvider() : _dio = Dio() {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    _authService = AuthService(_dio);
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      try {
        _user = await _authService.getProfile();
        notifyListeners();
      } catch (e) {
        await StorageService.clearAll();
      }
    }
  }
  
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authService.login({
        'username_or_email': email,
        'password': password,
      });
      
      await _handleAuthResponse(response);
    } catch (e) {
      _setError(_parseError(e));
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authService.register({
        'username': username,
        'email': email,
        'password': password,
        if (fullName != null) 'full_name': fullName,
      });
      
      await _handleAuthResponse(response);
    } catch (e) {
      _setError(_parseError(e));
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      await StorageService.clearAll();
      _user = null;
      notifyListeners();
    }
  }
  
  Future<void> _handleAuthResponse(AuthResponse response) async {
    await StorageService.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    _user = response.user;
    notifyListeners();
  }
  
  String _parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'];
      }
      if (error.response?.statusCode == 429) {
        return 'Too many requests. Please try again later.';
      }
    }
    return 'An error occurred. Please try again.';
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
```

### Environment Provider

**lib/providers/environment_provider.dart:**
```dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/environment.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EnvironmentProvider extends ChangeNotifier {
  final Dio _dio;
  late final ApiService _apiService;
  
  List<Environment> _environments = [];
  bool _isLoading = false;
  String? _error;
  
  List<Environment> get environments => _environments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  EnvironmentProvider() : _dio = Dio() {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    _apiService = ApiService(_dio);
  }
  
  Future<void> fetchEnvironments() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _environments = await _apiService.getEnvironments();
      notifyListeners();
    } catch (e) {
      _setError(_parseError(e));
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> createEnvironment({
    required String name,
    required String template,
    Resources? resources,
    Map<String, String>? environmentVariables,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final request = CreateEnvironmentRequest(
        name: name,
        template: template,
        resources: resources,
        environmentVariables: environmentVariables,
      );
      
      final environment = await _apiService.createEnvironment(request);
      _environments.add(environment);
      notifyListeners();
    } catch (e) {
      _setError(_parseError(e));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> deleteEnvironment(String id) async {
    try {
      await _apiService.deleteEnvironment(id);
      _environments.removeWhere((env) => env.id == id);
      notifyListeners();
    } catch (e) {
      _setError(_parseError(e));
      rethrow;
    }
  }
  
  Future<void> startEnvironment(String id) async {
    try {
      await _apiService.startEnvironment(id);
      await fetchEnvironments(); // Refresh to get updated status
    } catch (e) {
      _setError(_parseError(e));
      rethrow;
    }
  }
  
  Future<void> stopEnvironment(String id) async {
    try {
      await _apiService.stopEnvironment(id);
      await fetchEnvironments(); // Refresh to get updated status
    } catch (e) {
      _setError(_parseError(e));
      rethrow;
    }
  }
  
  String _parseError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'];
      }
    }
    return 'An error occurred. Please try again.';
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
```

## UI Components

### Enhanced Terminal Screen with Multiple WebSocket Support

**lib/screens/terminal_screen.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../models/environment.dart';
import '../services/terminal_websocket_service.dart';
import '../services/logs_websocket_service.dart';

class TerminalScreen extends StatefulWidget {
  final Environment environment;
  
  const TerminalScreen({
    Key? key,
    required this.environment,
  }) : super(key: key);
  
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> with TickerProviderStateMixin {
  late final Terminal terminal;
  late final TerminalWebSocketService terminalWebSocket;
  late final LogsWebSocketService logsWebSocket;
  late final TerminalController terminalController;
  late final TabController tabController;
  
  ConnectionStatus _terminalConnectionStatus = ConnectionStatus.connecting;
  ConnectionStatus _logsConnectionStatus = ConnectionStatus.connecting;
  EnvironmentInfo? _environmentInfo;
  List<LogEntry> _logs = [];
  
  @override
  void initState() {
    super.initState();
    
    tabController = TabController(length: 2, vsync: this);
    
    // Initialize terminal
    terminal = Terminal(
      maxLines: 10000,
    );
    
    terminalController = TerminalController();
    
    // Initialize WebSocket services
    terminalWebSocket = TerminalWebSocketService(
      environmentId: widget.environment.id,
    );
    
    logsWebSocket = LogsWebSocketService(
      environmentId: widget.environment.id,
      follow: true,
    );
    
    _setupTerminalWebSocket();
    _setupLogsWebSocket();
    
    // Setup terminal handlers
    terminal.onOutput = (data) {
      terminalWebSocket.sendCommand(data);
    };
    
    terminal.onResize = (width, height) {
      terminalWebSocket.resizeTerminal(width, height);
    };
    
    // Connect both WebSockets
    terminalWebSocket.connect();
    logsWebSocket.connect();
  }
  
  void _setupTerminalWebSocket() {
    // Listen to terminal output
    terminalWebSocket.terminalOutput.listen((output) {
      if (output.isError) {
        terminal.write('\x1b[31m${output.data}\x1b[0m'); // Red color for errors
      } else {
        terminal.write(output.data);
      }
    });
    
    // Listen to connection status
    terminalWebSocket.connectionStatus.listen((status) {
      setState(() {
        _terminalConnectionStatus = status;
      });
      
      if (status == ConnectionStatus.error) {
        _showSnackBar('Terminal connection error', Colors.red);
      } else if (status == ConnectionStatus.connected) {
        _showSnackBar('Terminal connected', Colors.green);
      }
    });
    
    // Listen to environment info
    terminalWebSocket.environmentInfo.listen((envInfo) {
      setState(() {
        _environmentInfo = envInfo;
      });
      
      if (envInfo.message != null) {
        terminal.write('\x1b[32m${envInfo.message}\x1b[0m\n'); // Green welcome message
      }
    });
  }
  
  void _setupLogsWebSocket() {
    // Listen to logs
    logsWebSocket.logs.listen((logEntry) {
      setState(() {
        _logs.add(logEntry);
        // Keep only last 1000 log entries
        if (_logs.length > 1000) {
          _logs.removeAt(0);
        }
      });
    });
    
    // Listen to connection status
    logsWebSocket.connectionStatus.listen((status) {
      setState(() {
        _logsConnectionStatus = status;
      });
    });
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  void dispose() {
    terminalWebSocket.disconnect();
    logsWebSocket.disconnect();
    tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.environment.name),
            if (_environmentInfo != null)
              Text(
                '${_environmentInfo!.template} • ${_environmentInfo!.status}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          _buildConnectionIndicator('Terminal', _terminalConnectionStatus),
          SizedBox(width: 8),
          _buildConnectionIndicator('Logs', _logsConnectionStatus),
          SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear', child: Text('Clear Terminal')),
              PopupMenuItem(value: 'reconnect', child: Text('Reconnect')),
              PopupMenuItem(value: 'resize', child: Text('Resize Terminal')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: 'Terminal', icon: Icon(Icons.terminal)),
            Tab(text: 'Logs', icon: Icon(Icons.list_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildTerminalTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }
  
  Widget _buildTerminalTab() {
    return SafeArea(
      child: Column(
        children: [
          if (_terminalConnectionStatus != ConnectionStatus.connected)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: _terminalConnectionStatus == ConnectionStatus.error 
                  ? Colors.red.shade100 
                  : Colors.orange.shade100,
              child: Text(
                _terminalConnectionStatus == ConnectionStatus.connecting
                    ? 'Connecting to terminal...'
                    : _terminalConnectionStatus == ConnectionStatus.error
                        ? 'Terminal connection failed. Retrying...'
                        : 'Terminal disconnected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _terminalConnectionStatus == ConnectionStatus.error 
                      ? Colors.red.shade800 
                      : Colors.orange.shade800,
                ),
              ),
            ),
          Expanded(
            child: TerminalView(
              terminal,
              controller: terminalController,
              textStyle: const TerminalStyle(
                fontSize: 14,
                fontFamily: 'Menlo, Monaco, Consolas, monospace',
              ),
              theme: const TerminalTheme(
                cursor: Color(0xFFaeafad),
                selection: Color(0xFF515151),
                foreground: Color(0xFFcccccc),
                background: Color(0xFF1e1e1e),
                black: Color(0xFF000000),
                red: Color(0xFFcd3131),
                green: Color(0xFF0dbc79),
                yellow: Color(0xFFe5e510),
                blue: Color(0xFF2472c8),
                magenta: Color(0xFFbc3fbc),
                cyan: Color(0xFF11a8cd),
                white: Color(0xFFe5e5e5),
                brightBlack: Color(0xFF666666),
                brightRed: Color(0xFFf14c4c),
                brightGreen: Color(0xFF23d18b),
                brightYellow: Color(0xFFf5f543),
                brightBlue: Color(0xFF3b8eea),
                brightMagenta: Color(0xFFd670d6),
                brightCyan: Color(0xFF29b8db),
                brightWhite: Color(0xFFffffff),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16),
              SizedBox(width: 8),
              Text('Live log stream for ${widget.environment.name}'),
              Spacer(),
              Text('${_logs.length} entries'),
            ],
          ),
        ),
        Expanded(
          child: _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Waiting for log entries...'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildLogEntry(log);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildLogEntry(LogEntry log) {
    Color levelColor;
    IconData levelIcon;
    
    switch (log.level) {
      case LogLevel.debug:
        levelColor = Colors.grey;
        levelIcon = Icons.bug_report;
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        levelIcon = Icons.info;
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case LogLevel.error:
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(levelIcon, size: 16, color: levelColor),
          SizedBox(width: 8),
          Text(
            log.timestamp.toLocal().toString().substring(11, 19),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionIndicator(String label, ConnectionStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        icon = Icons.circle;
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        icon = Icons.circle;
        break;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        color = Colors.red;
        icon = Icons.circle;
        break;
    }
    
    return Tooltip(
      message: '$label: ${status.toString().split('.').last}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          SizedBox(height: 2),
          Text(
            label.substring(0, 1),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        terminal.buffer.clear();
        terminal.buffer.setCursor(0, 0);
        break;
      case 'reconnect':
        terminalWebSocket.disconnect();
        logsWebSocket.disconnect();
        Future.delayed(Duration(seconds: 1), () {
          terminalWebSocket.connect();
          logsWebSocket.connect();
        });
        break;
      case 'resize':
        _showResizeDialog();
        break;
    }
  }
  
  void _showResizeDialog() {
    final colsController = TextEditingController(text: '80');
    final rowsController = TextEditingController(text: '24');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resize Terminal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colsController,
              decoration: InputDecoration(labelText: 'Columns'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: rowsController,
              decoration: InputDecoration(labelText: 'Rows'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final cols = int.tryParse(colsController.text) ?? 80;
              final rows = int.tryParse(rowsController.text) ?? 24;
              terminalWebSocket.resizeTerminal(cols, rows);
              Navigator.pop(context);
            },
            child: Text('Resize'),
          ),
        ],
      ),
    );
  }
}
```

### Environment Card Widget

**lib/widgets/environment_card.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/environment.dart';

class EnvironmentCard extends StatelessWidget {
  final Environment environment;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onDelete;
  
  const EnvironmentCard({
    Key? key,
    required this.environment,
    required this.onTap,
    required this.onStart,
    required this.onStop,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          environment.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Template: ${environment.template}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 16),
              _buildResourceUsage(context),
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    
    switch (environment.status) {
      case 'running':
        color = Colors.green;
        icon = Icons.play_circle_outline;
        break;
      case 'stopped':
        color = Colors.orange;
        icon = Icons.pause_circle_outline;
        break;
      case 'error':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        environment.status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }
  
  Widget _buildResourceUsage(BuildContext context) {
    return Column(
      children: [
        _buildUsageIndicator(
          context,
          'CPU',
          environment.cpuUsage ?? 0,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildUsageIndicator(
          context,
          'Memory',
          environment.memoryUsage ?? 0,
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildUsageIndicator(
          context,
          'Storage',
          environment.storageUsage ?? 0,
          Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildUsageIndicator(
    BuildContext context,
    String label,
    double usage,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: usage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${usage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (environment.status == 'stopped')
          TextButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          )
        else if (environment.status == 'running')
          TextButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }
}
```

## Complete Example App

**lib/main.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/environment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/environments_screen.dart';

void main() {
  runApp(const DevPocketApp());
}

class DevPocketApp extends StatelessWidget {
  const DevPocketApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EnvironmentProvider()),
      ],
      child: MaterialApp(
        title: 'DevPocket',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return const EnvironmentsScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
```

**lib/config/constants.dart:**
```dart
class Constants {
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';
  
  // Production URLs
  // static const String apiBaseUrl = 'https://devpocket-api.goon.vn';
  // static const String wsBaseUrl = 'wss://devpocket-api.goon.vn';
}
```

## WebSocket Testing and Debugging

### Testing WebSocket Connections

**lib/utils/websocket_tester.dart:**
```dart
import 'dart:convert';
import 'dart:io';
import '../services/storage_service.dart';

class WebSocketTester {
  static Future<bool> testTerminalConnection(String environmentId) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return false;
      
      final uri = Uri.parse('ws://localhost:8000/api/v1/ws/terminal/$environmentId?token=$token');
      final socket = await WebSocket.connect(uri.toString());
      
      // Send test ping
      socket.add(json.encode({'type': 'ping'}));
      
      // Wait for pong response
      await socket.take(1).first;
      
      await socket.close();
      return true;
    } catch (e) {
      print('WebSocket test failed: $e');
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> diagnoseConnection(String environmentId) async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'environment_id': environmentId,
      'tests': <String, dynamic>{},
    };
    
    // Test token availability
    final token = await StorageService.getAccessToken();
    result['tests']['token_available'] = token != null;
    
    if (token == null) {
      result['error'] = 'No authentication token available';
      return result;
    }
    
    // Test network connectivity
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.devpocket.io/health'));
      final response = await request.close();
      result['tests']['api_reachable'] = response.statusCode == 200;
      client.close();
    } catch (e) {
      result['tests']['api_reachable'] = false;
      result['network_error'] = e.toString();
    }
    
    // Test WebSocket connection
    result['tests']['websocket_connection'] = await testTerminalConnection(environmentId);
    
    return result;
  }
}
```

### WebSocket Debug Widget

**lib/widgets/websocket_debug_widget.dart:**
```dart
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../utils/websocket_tester.dart';

class WebSocketDebugWidget extends StatefulWidget {
  final String environmentId;
  
  const WebSocketDebugWidget({Key? key, required this.environmentId}) : super(key: key);
  
  @override
  State<WebSocketDebugWidget> createState() => _WebSocketDebugWidgetState();
}

class _WebSocketDebugWidgetState extends State<WebSocketDebugWidget> {
  late WebSocketService _webSocket;
  List<WebSocketMessage> _messages = [];
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Map<String, dynamic>? _diagnostics;
  
  @override
  void initState() {
    super.initState();
    _webSocket = WebSocketService(environmentId: widget.environmentId);
    
    _webSocket.messages.listen((message) {
      setState(() {
        _messages.add(message);
        // Keep only last 50 messages
        if (_messages.length > 50) {
          _messages.removeAt(0);
        }
      });
    });
    
    _webSocket.connectionStatus.listen((status) {
      setState(() {
        _status = status;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Debug'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          _buildStatusBar(),
          if (_diagnostics != null) _buildDiagnostics(),
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _status == ConnectionStatus.connected ? null : () {
              _webSocket.connect();
            },
            child: Text('Connect'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _status != ConnectionStatus.connected ? null : () {
              _webSocket.disconnect();
            },
            child: Text('Disconnect'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _status != ConnectionStatus.connected ? null : () {
              _webSocket.sendPing();
            },
            child: Text('Ping'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;
    
    switch (_status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusText = 'Disconnected';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusText = 'Error';
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.circle, color: statusColor, size: 12),
          SizedBox(width: 8),
          Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          Spacer(),
          Text('Messages: ${_messages.length}'),
        ],
      ),
    );
  }
  
  Widget _buildDiagnostics() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ..._diagnostics!['tests'].entries.map<Widget>((entry) => 
            Row(
              children: [
                Icon(
                  entry.value == true ? Icons.check_circle : Icons.error,
                  color: entry.value == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(entry.key.replaceAll('_', ' ').toUpperCase()),
              ],
            ),
          ).toList(),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(message.type),
                      backgroundColor: _getMessageTypeColor(message.type),
                    ),
                    Spacer(),
                    Text(
                      message.timestamp.toString().substring(11, 19),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (message.data != null) ..[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message.data.toString(),
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getMessageTypeColor(String type) {
    switch (type) {
      case 'welcome':
        return Colors.green.shade100;
      case 'output':
        return Colors.blue.shade100;
      case 'error':
        return Colors.red.shade100;
      case 'pong':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
  
  void _runDiagnostics() async {
    final diagnostics = await WebSocketTester.diagnoseConnection(widget.environmentId);
    setState(() {
      _diagnostics = diagnostics;
    });
  }
  
  @override
  void dispose() {
    _webSocket.disconnect();
    super.dispose();
  }
}
```

## Running the App

1. Generate code:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

2. Run the app:
```bash
flutter run
```

3. Test WebSocket connections:
```bash
# Enable debug mode in main.dart
flutter run --dart-define=DEBUG_WEBSOCKETS=true
```

## Testing

**test/services/auth_service_test.dart:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([Dio])
void main() {
  group('AuthService', () {
    test('login returns AuthResponse', () async {
      // Test implementation
    });
    
    test('handles 401 error', () async {
      // Test implementation
    });
  });
}
```

**test/services/websocket_service_test.dart:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../lib/services/websocket_service.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

void main() {
  group('WebSocketService', () {
    late WebSocketService webSocketService;
    late MockWebSocketChannel mockChannel;
    
    setUp(() {
      mockChannel = MockWebSocketChannel();
      webSocketService = WebSocketService(environmentId: 'test-env');
    });
    
    test('connects successfully', () async {
      // Test WebSocket connection
      expect(webSocketService.isConnected, isFalse);
      // Add connection test logic
    });
    
    test('handles connection errors', () async {
      // Test error handling
    });
    
    test('sends messages correctly', () async {
      // Test message sending
    });
    
    test('reconnects on connection loss', () async {
      // Test reconnection logic
    });
    
    test('handles rate limiting', () async {
      // Test rate limiting behavior
    });
  });
}
```

**test/integration/websocket_integration_test.dart:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart' as app;
import 'package:myapp/services/websocket_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('WebSocket Integration Tests', () {
    testWidgets('Terminal WebSocket connection and messaging', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Login
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Navigate to environment
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      
      // Open terminal
      await tester.tap(find.byIcon(Icons.terminal));
      await tester.pumpAndSettle();
      
      // Wait for WebSocket connection
      await tester.pump(Duration(seconds: 3));
      
      // Verify connection indicator is green
      expect(find.byIcon(Icons.circle), findsWidgets);
      
      // Test sending command
      await tester.enterText(find.byType(TextField), 'echo "Hello World"');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(Duration(seconds: 1));
      
      // Verify output in terminal
      expect(find.textContaining('Hello World'), findsOneWidget);
    });
    
    testWidgets('Log streaming WebSocket', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to logs tab
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();
      
      // Wait for log entries
      await tester.pump(Duration(seconds: 5));
      
      // Verify log entries are displayed
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
```

## Troubleshooting WebSocket Issues

### Common Issues and Solutions

1. **Connection Timeouts**
   ```dart
   // Increase timeout in WebSocket configuration
   final uri = Uri.parse(url);
   final socket = await WebSocket.connect(
     uri.toString(),
     headers: headers,
   ).timeout(Duration(seconds: 10));
   ```

2. **Authentication Failures**
   ```dart
   // Verify token before connecting
   Future<bool> _verifyToken() async {
     try {
       final response = await dio.get('/api/v1/auth/me');
       return response.statusCode == 200;
     } catch (e) {
       return false;
     }
   }
   ```

3. **Memory Leaks**
   ```dart
   @override
   void dispose() {
     // Always close streams and cancel timers
     _pingTimer?.cancel();
     _reconnectTimer?.cancel();
     _outputController.close();
     _connectionController.close();
     _webSocket?.disconnect();
     super.dispose();
   }
   ```

4. **Handling Background/Foreground Transitions**
   ```dart
   class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
     @override
     void initState() {
       super.initState();
       WidgetsBinding.instance.addObserver(this);
     }
     
     @override
     void didChangeAppLifecycleState(AppLifecycleState state) {
       if (state == AppLifecycleState.paused) {
         // Disconnect WebSocket when app goes to background
         webSocketService.disconnect();
       } else if (state == AppLifecycleState.resumed) {
         // Reconnect when app comes to foreground
         webSocketService.connect();
       }
     }
   }
   ```

### Performance Optimization

1. **Message Buffering**
   ```dart
   class WebSocketBuffer {
     final List<String> _buffer = [];
     Timer? _flushTimer;
     
     void addMessage(String message) {
       _buffer.add(message);
       _scheduleFlush();
     }
     
     void _scheduleFlush() {
       _flushTimer?.cancel();
       _flushTimer = Timer(Duration(milliseconds: 100), _flush);
     }
     
     void _flush() {
       if (_buffer.isNotEmpty) {
         final batch = _buffer.join('\n');
         terminal.write(batch);
         _buffer.clear();
       }
     }
   }
   ```

2. **Connection Pooling**
   ```dart
   class WebSocketPool {
     final Map<String, WebSocketService> _connections = {};
     
     WebSocketService getConnection(String environmentId) {
       return _connections.putIfAbsent(
         environmentId,
         () => WebSocketService(environmentId: environmentId),
       );
     }
     
     void closeAll() {
       _connections.values.forEach((ws) => ws.disconnect());
       _connections.clear();
     }
   }
   ```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dio Package](https://pub.dev/packages/dio)
- [Provider Package](https://pub.dev/packages/provider)
- [XTerm Package](https://pub.dev/packages/xterm)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)
- [DevPocket API Documentation](http://localhost:8000/docs)
- [WebSocket RFC 6455](https://tools.ietf.org/html/rfc6455)