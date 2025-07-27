# WebSocket Terminal Implementation Guide

This document provides a complete implementation guide for integrating WebSocket terminal functionality into the DevPocket Flutter mobile app.

## Table of Contents

1. [Overview](#overview)
2. [WebSocket API Specification](#websocket-api-specification)
3. [Flutter Dependencies](#flutter-dependencies)
4. [Authentication](#authentication)
5. [WebSocket Connection](#websocket-connection)
6. [Message Protocol](#message-protocol)
7. [Terminal UI Implementation](#terminal-ui-implementation)
8. [Complete Flutter Implementation](#complete-flutter-implementation)
9. [Error Handling](#error-handling)
10. [Best Practices](#best-practices)
11. [Testing](#testing)

## Overview

The DevPocket WebSocket terminal provides real-time command execution in Kubernetes-based development environments. The implementation supports:

- Real-time command execution
- Bidirectional communication (input/output)
- Terminal session management
- Connection health monitoring (ping/pong)
- Proper cleanup and error handling

## WebSocket API Specification

### Endpoint
```
wss://{API_BASE_URL}/api/v1/ws/terminal/{environment_id}?token={jwt_token}
```

**Parameters:**
- `environment_id`: String - The ID of the development environment
- `token`: String - JWT access token for authentication

**Supported Domains:**
- Production: `wss://api.devpocket.app`
- Staging: `wss://devpocket-api.goon.vn`

### Connection Flow

1. **Authentication**: JWT token validated on connection
2. **Welcome Message**: Server sends environment details
3. **Command Execution**: Client sends commands, server responds with output
4. **Heartbeat**: Ping/pong messages for connection health
5. **Cleanup**: Proper disconnection and session cleanup

## Flutter Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  web_socket_channel: ^2.4.0
  flutter_pty: ^0.3.0  # For terminal UI (optional)
  xterm: ^3.4.0        # Alternative terminal UI
  provider: ^6.0.5     # State management
  
dev_dependencies:
  mockito: ^5.4.2      # For testing
```

## Authentication

### JWT Token Structure

```dart
class AuthToken {
  final String sub;        // User ID
  final String username;   // Username
  final String email;      // User email
  final DateTime exp;      // Expiration time
  final DateTime iat;      // Issued at time
  final String type;       // "access_token"
}
```

### Token Generation Example

```dart
import 'package:jwt_decode/jwt_decode.dart';

class AuthService {
  String? _accessToken;
  
  // Get current access token
  String? get accessToken => _accessToken;
  
  // Check if token is valid and not expired
  bool isTokenValid() {
    if (_accessToken == null) return false;
    
    try {
      final payload = Jwt.parseJwt(_accessToken!);
      final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isBefore(exp);
    } catch (e) {
      return false;
    }
  }
  
  // Refresh token if needed
  Future<String?> getValidToken() async {
    if (isTokenValid()) {
      return _accessToken;
    }
    
    // Implement token refresh logic here
    await refreshToken();
    return _accessToken;
  }
}
```

## WebSocket Connection

### WebSocket Service Implementation

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketTerminalService {
  static const String _baseWsUrl = 'wss://api.devpocket.app';
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<TerminalMessage> _messageController = StreamController.broadcast();
  final StreamController<ConnectionState> _connectionController = StreamController.broadcast();
  
  Timer? _pingTimer;
  bool _isConnected = false;
  String? _environmentId;
  
  // Streams for UI to listen to
  Stream<TerminalMessage> get messageStream => _messageController.stream;
  Stream<ConnectionState> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _isConnected;
  
  // Connect to WebSocket terminal
  Future<bool> connect(String environmentId, String accessToken) async {
    try {
      _environmentId = environmentId;
      final uri = Uri.parse('$_baseWsUrl/api/v1/ws/terminal/$environmentId?token=$accessToken');
      
      _connectionController.add(ConnectionState.connecting);
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      _isConnected = true;
      _connectionController.add(ConnectionState.connected);
      
      // Start ping timer for connection health
      _startPingTimer();
      
      return true;
    } catch (e) {
      _connectionController.add(ConnectionState.error);
      print('WebSocket connection error: $e');
      return false;
    }
  }
  
  // Send command to terminal
  void sendCommand(String command) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'input',
      'data': command,
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  // Send ping for connection health
  void sendPing() {
    if (!_isConnected || _channel == null) return;
    
    final message = {'type': 'ping'};
    _channel!.sink.add(json.encode(message));
  }
  
  // Handle terminal resize
  void resizeTerminal(int cols, int rows) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'resize',
      'cols': cols,
      'rows': rows,
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  // Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = json.decode(data);
      final messageType = message['type'] as String?;
      
      switch (messageType) {
        case 'welcome':
          _handleWelcomeMessage(message);
          break;
        case 'output':
          _handleOutputMessage(message);
          break;
        case 'pong':
          _handlePongMessage();
          break;
        case 'error':
          _handleErrorMessage(message);
          break;
        default:
          print('Unknown message type: $messageType');
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }
  
  void _handleWelcomeMessage(Map<String, dynamic> message) {
    final environmentData = message['environment'] as Map<String, dynamic>?;
    final welcomeMessage = TerminalMessage.welcome(
      message: message['message'] as String? ?? 'Connected',
      environment: environmentData,
    );
    
    _messageController.add(welcomeMessage);
    print('Connected to environment: ${environmentData?['name']}');
  }
  
  void _handleOutputMessage(Map<String, dynamic> message) {
    final output = message['data'] as String? ?? '';
    final outputMessage = TerminalMessage.output(output);
    _messageController.add(outputMessage);
  }
  
  void _handlePongMessage() {
    print('Received pong - connection healthy');
  }
  
  void _handleErrorMessage(Map<String, dynamic> message) {
    final errorMsg = message['message'] as String? ?? 'Unknown error';
    final errorMessage = TerminalMessage.error(errorMsg);
    _messageController.add(errorMessage);
  }
  
  void _handleError(error) {
    print('WebSocket error: $error');
    _connectionController.add(ConnectionState.error);
    _cleanup();
  }
  
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _connectionController.add(ConnectionState.disconnected);
    _cleanup();
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      sendPing();
    });
  }
  
  void _cleanup() {
    _isConnected = false;
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
  }
  
  // Disconnect from WebSocket
  void disconnect() {
    _cleanup();
    _connectionController.add(ConnectionState.disconnected);
  }
  
  void dispose() {
    _cleanup();
    _messageController.close();
    _connectionController.close();
  }
}
```

## Message Protocol

### Message Types

#### 1. Welcome Message (Server → Client)
```json
{
  "type": "welcome",
  "message": "Connected to goon",
  "environment": {
    "name": "goon",
    "status": "running",
    "template": "ubuntu",
    "pod_name": "goon-ea07939a-588cf5dd4f-pnftp"
  }
}
```

#### 2. Command Input (Client → Server)
```json
{
  "type": "input",
  "data": "ls -la"
}
```

#### 3. Command Output (Server → Client)
```json
{
  "type": "output",
  "data": "$ ls -la\ntotal 8\ndrwxr-xr-x 2 root root 4096 Jul 26 16:27 .\ndrwxr-xr-x 3 root root 4096 Jul 26 16:27 ..\n"
}
```

#### 4. Ping/Pong (Bidirectional)
```json
// Ping
{"type": "ping"}

// Pong
{"type": "pong"}
```

#### 5. Terminal Resize (Client → Server)
```json
{
  "type": "resize",
  "cols": 80,
  "rows": 24
}
```

#### 6. Error Message (Server → Client)
```json
{
  "type": "error",
  "message": "Command execution failed"
}
```

### Message Models

```dart
enum TerminalMessageType {
  welcome,
  output,
  error,
  pong,
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class TerminalMessage {
  final TerminalMessageType type;
  final String data;
  final Map<String, dynamic>? environment;
  final DateTime timestamp;
  
  TerminalMessage._({
    required this.type,
    required this.data,
    this.environment,
  }) : timestamp = DateTime.now();
  
  factory TerminalMessage.welcome({
    required String message,
    Map<String, dynamic>? environment,
  }) {
    return TerminalMessage._(
      type: TerminalMessageType.welcome,
      data: message,
      environment: environment,
    );
  }
  
  factory TerminalMessage.output(String output) {
    return TerminalMessage._(
      type: TerminalMessageType.output,
      data: output,
    );
  }
  
  factory TerminalMessage.error(String error) {
    return TerminalMessage._(
      type: TerminalMessageType.error,
      data: error,
    );
  }
  
  factory TerminalMessage.pong() {
    return TerminalMessage._(
      type: TerminalMessageType.pong,
      data: 'pong',
    );
  }
}
```

## Terminal UI Implementation

### Terminal State Management

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TerminalProvider extends ChangeNotifier {
  final WebSocketTerminalService _wsService = WebSocketTerminalService();
  
  final List<String> _outputLines = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _currentEnvironmentId;
  Map<String, dynamic>? _environmentInfo;
  
  // Getters
  List<String> get outputLines => List.unmodifiable(_outputLines);
  TextEditingController get inputController => _inputController;
  ScrollController get scrollController => _scrollController;
  ConnectionState get connectionState => _connectionState;
  String? get currentEnvironmentId => _currentEnvironmentId;
  Map<String, dynamic>? get environmentInfo => _environmentInfo;
  
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isConnecting => _connectionState == ConnectionState.connecting;
  
  TerminalProvider() {
    _initializeListeners();
  }
  
  void _initializeListeners() {
    // Listen to connection state changes
    _wsService.connectionStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
    
    // Listen to terminal messages
    _wsService.messageStream.listen((message) {
      switch (message.type) {
        case TerminalMessageType.welcome:
          _handleWelcomeMessage(message);
          break;
        case TerminalMessageType.output:
          _handleOutputMessage(message);
          break;
        case TerminalMessageType.error:
          _handleErrorMessage(message);
          break;
        case TerminalMessageType.pong:
          // Handle pong if needed
          break;
      }
    });
  }
  
  void _handleWelcomeMessage(TerminalMessage message) {
    _environmentInfo = message.environment;
    addOutputLine('🎉 ${message.data}');
    
    if (_environmentInfo != null) {
      addOutputLine('Environment: ${_environmentInfo!['name']}');
      addOutputLine('Status: ${_environmentInfo!['status']}');
      addOutputLine('Template: ${_environmentInfo!['template']}');
      addOutputLine('');
    }
    
    notifyListeners();
  }
  
  void _handleOutputMessage(TerminalMessage message) {
    // Split output into lines and add them
    final lines = message.data.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty || lines.length == 1) {
        addOutputLine(line);
      }
    }
  }
  
  void _handleErrorMessage(TerminalMessage message) {
    addOutputLine('❌ Error: ${message.data}');
  }
  
  // Connect to environment
  Future<bool> connectToEnvironment(String environmentId, String accessToken) async {
    _currentEnvironmentId = environmentId;
    addOutputLine('🔌 Connecting to environment...');
    
    final success = await _wsService.connect(environmentId, accessToken);
    
    if (!success) {
      addOutputLine('❌ Failed to connect to environment');
    }
    
    return success;
  }
  
  // Send command
  void sendCommand(String command) {
    if (!isConnected) return;
    
    // Clear input
    _inputController.clear();
    
    // Send command
    _wsService.sendCommand(command);
    
    // Auto-scroll to bottom
    _scrollToBottom();
  }
  
  // Add output line
  void addOutputLine(String line) {
    _outputLines.add(line);
    notifyListeners();
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Handle terminal resize
  void resizeTerminal(int cols, int rows) {
    _wsService.resizeTerminal(cols, rows);
  }
  
  // Clear terminal
  void clearTerminal() {
    _outputLines.clear();
    notifyListeners();
  }
  
  // Disconnect
  void disconnect() {
    _wsService.disconnect();
    _currentEnvironmentId = null;
    _environmentInfo = null;
  }
  
  @override
  void dispose() {
    _wsService.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

### Terminal Screen Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TerminalScreen extends StatefulWidget {
  final String environmentId;
  final String accessToken;
  
  const TerminalScreen({
    Key? key,
    required this.environmentId,
    required this.accessToken,
  }) : super(key: key);
  
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late TerminalProvider _terminalProvider;
  final FocusNode _inputFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _terminalProvider = context.read<TerminalProvider>();
    
    // Connect to environment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _terminalProvider.connectToEnvironment(
        widget.environmentId,
        widget.accessToken,
      );
    });
  }
  
  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Consumer<TerminalProvider>(
          builder: (context, provider, child) {
            final envInfo = provider.environmentInfo;
            return Text(
              envInfo != null ? 'Terminal - ${envInfo['name']}' : 'Terminal',
              style: TextStyle(color: Colors.white),
            );
          },
        ),
        actions: [
          Consumer<TerminalProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isConnected 
                    ? Icons.cloud_done 
                    : Icons.cloud_off,
                  color: provider.isConnected 
                    ? Colors.green 
                    : Colors.red,
                ),
                onPressed: () {
                  if (!provider.isConnected) {
                    provider.connectToEnvironment(
                      widget.environmentId,
                      widget.accessToken,
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _terminalProvider.clearTerminal();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Consumer<TerminalProvider>(
            builder: (context, provider, child) {
              if (provider.isConnecting) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.orange,
                  child: Text(
                    '🔌 Connecting to terminal...',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              } else if (!provider.isConnected) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.red,
                  child: Text(
                    '❌ Disconnected - Tap to reconnect',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          
          // Terminal Output
          Expanded(
            child: Consumer<TerminalProvider>(
              builder: (context, provider, child) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  child: ListView.builder(
                    controller: provider.scrollController,
                    itemCount: provider.outputLines.length,
                    itemBuilder: (context, index) {
                      final line = provider.outputLines[index];
                      return SelectableText(
                        line,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                          color: Colors.green[300],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Command Input
          Consumer<TerminalProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$ ',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        color: Colors.green[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: provider.inputController,
                        focusNode: _inputFocusNode,
                        enabled: provider.isConnected,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: provider.isConnected 
                            ? 'Enter command...' 
                            : 'Not connected',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                        ),
                        onSubmitted: (command) {
                          if (command.trim().isNotEmpty) {
                            provider.sendCommand(command.trim());
                          }
                          _inputFocusNode.requestFocus();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.green[300]),
                      onPressed: provider.isConnected
                        ? () {
                            final command = provider.inputController.text.trim();
                            if (command.isNotEmpty) {
                              provider.sendCommand(command);
                            }
                            _inputFocusNode.requestFocus();
                          }
                        : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## Complete Flutter Implementation

### Main App Integration

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TerminalProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: 'DevPocket Terminal',
        theme: ThemeData.dark(),
        home: TerminalScreen(
          environmentId: '68850093852e1ff1492d3d87', // Your environment ID
          accessToken: 'your-jwt-token-here',
        ),
      ),
    );
  }
}
```

### Quick Command Buttons

```dart
class QuickCommandsWidget extends StatelessWidget {
  final List<QuickCommand> commands = [
    QuickCommand('pwd', 'Show current directory'),
    QuickCommand('ls -la', 'List files with details'),
    QuickCommand('whoami', 'Show current user'),
    QuickCommand('ps aux', 'Show running processes'),
    QuickCommand('df -h', 'Show disk usage'),
    QuickCommand('top', 'Show system processes'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: commands.length,
        itemBuilder: (context, index) {
          final command = commands[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(command.command),
              onPressed: () {
                final provider = context.read<TerminalProvider>();
                provider.sendCommand(command.command);
              },
            ),
          );
        },
      ),
    );
  }
}

class QuickCommand {
  final String command;
  final String description;
  
  QuickCommand(this.command, this.description);
}
```

## Error Handling

### Connection Error Handling

```dart
enum TerminalError {
  connectionFailed,
  authenticationFailed,
  environmentNotFound,
  commandExecutionFailed,
  networkError,
  tokenExpired,
}

class TerminalErrorHandler {
  static String getErrorMessage(TerminalError error) {
    switch (error) {
      case TerminalError.connectionFailed:
        return 'Failed to connect to terminal. Please check your internet connection.';
      case TerminalError.authenticationFailed:
        return 'Authentication failed. Please log in again.';
      case TerminalError.environmentNotFound:
        return 'Development environment not found or not running.';
      case TerminalError.commandExecutionFailed:
        return 'Command execution failed. Please try again.';
      case TerminalError.networkError:
        return 'Network error. Please check your connection.';
      case TerminalError.tokenExpired:
        return 'Session expired. Please log in again.';
    }
  }
  
  static void handleError(BuildContext context, TerminalError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            // Implement retry logic
          },
        ),
      ),
    );
  }
}
```

### Auto-Reconnection

```dart
class AutoReconnectService {
  static const int maxRetries = 5;
  static const Duration initialDelay = Duration(seconds: 1);
  
  static Future<void> attemptReconnection(
    TerminalProvider provider,
    String environmentId,
    String accessToken,
  ) async {
    int retryCount = 0;
    Duration delay = initialDelay;
    
    while (retryCount < maxRetries && !provider.isConnected) {
      await Future.delayed(delay);
      
      print('Reconnection attempt ${retryCount + 1}/$maxRetries');
      
      final success = await provider.connectToEnvironment(
        environmentId,
        accessToken,
      );
      
      if (success) {
        print('Reconnection successful');
        return;
      }
      
      retryCount++;
      delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
    }
    
    print('Failed to reconnect after $maxRetries attempts');
  }
}
```

## Best Practices

### 1. Memory Management
- Always dispose of controllers and providers
- Cancel timers and subscriptions properly
- Use `StreamSubscription.cancel()` for cleanup

### 2. UI Performance
- Use `ListView.builder` for large output
- Implement text virtualization for very long outputs
- Debounce rapid input/output updates

### 3. Security
- Validate JWT tokens before connection
- Handle token refresh automatically
- Never log sensitive information

### 4. User Experience
- Show clear connection status
- Provide quick command shortcuts
- Implement command history
- Auto-scroll to latest output

### 5. Error Recovery
- Implement automatic reconnection
- Show meaningful error messages
- Provide manual retry options

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

void main() {
  group('WebSocketTerminalService', () {
    late WebSocketTerminalService service;
    late MockWebSocketChannel mockChannel;
    
    setUp(() {
      service = WebSocketTerminalService();
      mockChannel = MockWebSocketChannel();
    });
    
    test('should connect successfully with valid token', () async {
      // Arrange
      const environmentId = 'test-env-id';
      const accessToken = 'valid-token';
      
      // Act
      final result = await service.connect(environmentId, accessToken);
      
      // Assert
      expect(result, isTrue);
      expect(service.isConnected, isTrue);
    });
    
    test('should handle command sending', () {
      // Arrange
      const command = 'ls -la';
      
      // Act
      service.sendCommand(command);
      
      // Assert
      // Verify command was sent through WebSocket
    });
    
    test('should handle disconnection properly', () {
      // Arrange
      service.connect('test-env', 'token');
      
      // Act
      service.disconnect();
      
      // Assert
      expect(service.isConnected, isFalse);
    });
  });
}
```

### Integration Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Terminal Integration Tests', () {
    testWidgets('should connect and execute commands', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(MyApp());
      
      // Wait for connection
      await tester.pump(Duration(seconds: 2));
      
      // Find command input field
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      
      // Enter a command
      await tester.enterText(inputField, 'pwd');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      
      // Wait for output
      await tester.pump(Duration(seconds: 1));
      
      // Verify output appears
      expect(find.textContaining('/home/devuser/workspace'), findsOneWidget);
    });
  });
}
```

## Production Configuration

### Environment Variables

```dart
class TerminalConfig {
  static const String prodBaseUrl = 'wss://api.devpocket.app';
  static const String stagingBaseUrl = 'wss://devpocket-api.goon.vn';
  
  static String get baseUrl {
    return const bool.fromEnvironment('dart.vm.product')
        ? prodBaseUrl
        : stagingBaseUrl;
  }
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration pingInterval = Duration(seconds: 30);
  static const int maxReconnectAttempts = 5;
}
```

### Performance Monitoring

```dart
class TerminalMetrics {
  static void trackConnection(String environmentId, bool success) {
    // Implement analytics tracking
    print('Connection ${success ? 'successful' : 'failed'} for $environmentId');
  }
  
  static void trackCommandExecution(String command, Duration duration) {
    // Track command execution performance
    print('Command "$command" executed in ${duration.inMilliseconds}ms');
  }
  
  static void trackError(String error, Map<String, dynamic> context) {
    // Track errors for debugging
    print('Terminal error: $error, context: $context');
  }
}
```

This comprehensive implementation guide provides everything needed to integrate WebSocket terminal functionality into your DevPocket Flutter app. The implementation supports real-time command execution, proper error handling, and follows Flutter best practices for maintainable and performant code.