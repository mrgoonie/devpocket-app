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
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── environment_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── environments_screen.dart
│   └── terminal_screen.dart
└── widgets/
    ├── environment_card.dart
    └── loading_indicator.dart
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
  
  Stream<String> get output => _outputController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  WebSocketService({required this.environmentId});

  Future<void> connect() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No auth token');
      
      final uri = Uri.parse(
        '${Constants.wsBaseUrl}/api/v1/ws/terminal/$environmentId?token=$token'
      );
      
      _channel = WebSocketChannel.connect(uri);
      _connectionController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      
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
      if (data['type'] == 'output') {
        _outputController.add(data['data']);
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _handleError(error) {
    _connectionController.add(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _handleDone() {
    _connectionController.add(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= 5) return;
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 2 << _reconnectAttempts);
    _reconnectAttempts++;
    
    _reconnectTimer = Timer(delay, () {
      connect();
    });
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

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _outputController.close();
    _connectionController.close();
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
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

### Terminal Screen

**lib/screens/terminal_screen.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../models/environment.dart';
import '../services/websocket_service.dart';

class TerminalScreen extends StatefulWidget {
  final Environment environment;
  
  const TerminalScreen({
    Key? key,
    required this.environment,
  }) : super(key: key);
  
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final Terminal terminal;
  late final WebSocketService webSocket;
  late final TerminalController terminalController;
  
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  
  @override
  void initState() {
    super.initState();
    
    terminal = Terminal(
      maxLines: 10000,
    );
    
    terminalController = TerminalController();
    
    webSocket = WebSocketService(environmentId: widget.environment.id);
    
    // Listen to WebSocket output
    webSocket.output.listen((data) {
      terminal.write(data);
    });
    
    // Listen to connection status
    webSocket.connectionStatus.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });
    
    // Handle terminal input
    terminal.onOutput = (data) {
      webSocket.sendCommand(data);
    };
    
    // Handle terminal resize
    terminal.onResize = (width, height) {
      webSocket.resize(width, height);
    };
    
    // Connect to WebSocket
    webSocket.connect();
  }
  
  @override
  void dispose() {
    webSocket.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.environment.name),
        actions: [
          _buildConnectionIndicator(),
        ],
      ),
      body: SafeArea(
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
    );
  }
  
  Widget _buildConnectionIndicator() {
    Color color;
    String tooltip;
    
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        color = Colors.green;
        tooltip = 'Connected';
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        tooltip = 'Connecting...';
        break;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        color = Colors.red;
        tooltip = 'Disconnected';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
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

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dio Package](https://pub.dev/packages/dio)
- [Provider Package](https://pub.dev/packages/provider)
- [XTerm Package](https://pub.dev/packages/xterm)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)