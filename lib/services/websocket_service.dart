import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants.dart';
import '../models/terminal_message.dart';

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
  reconnecting,
}

class WebSocketTerminalService {
  static const String _baseWsUrl = AppConstants.wsBaseUrl;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<TerminalMessage> _messageController = StreamController.broadcast();
  final StreamController<ConnectionStatus> _connectionController = StreamController.broadcast();
  
  Timer? _pingTimer;
  bool _isConnected = false;
  String? _environmentId;
  
  // Streams for UI to listen to
  Stream<TerminalMessage> get messageStream => _messageController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _isConnected;
  
  // Connect to WebSocket terminal
  Future<bool> connect(String environmentId, String accessToken) async {
    try {
      _environmentId = environmentId;
      final uri = Uri.parse('$_baseWsUrl/api/v1/ws/terminal/$environmentId?token=$accessToken');
      
      _connectionController.add(ConnectionStatus.connecting);
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      _isConnected = true;
      _connectionController.add(ConnectionStatus.connected);
      
      // Start ping timer for connection health
      _startPingTimer();
      
      return true;
    } catch (e) {
      _connectionController.add(ConnectionStatus.error);
      print('WebSocket connection error: $e');
      return false;
    }
  }
  
  // Send command to terminal
  void sendCommand(String command) {
    if (!_isConnected || _channel == null) return;
    
    // Add newline if not present
    final commandWithNewline = command.endsWith('\n') ? command : '$command\n';
    
    final message = {
      'type': 'input',
      'data': commandWithNewline,
    };
    
    print('Sending command: ${commandWithNewline.replaceAll('\n', '\\n')}');
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
      print('Raw WebSocket message: $data');
      final Map<String, dynamic> message = json.decode(data);
      final messageType = message['type'] as String?;
      print('Parsed message type: $messageType');
      
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
    print('Received output: ${output.replaceAll('\n', '\\n')}');
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
    _connectionController.add(ConnectionStatus.error);
    _cleanup();
  }
  
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _connectionController.add(ConnectionStatus.disconnected);
    _cleanup();
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
    _connectionController.add(ConnectionStatus.disconnected);
  }
  
  void dispose() {
    _cleanup();
    _messageController.close();
    _connectionController.close();
  }
}