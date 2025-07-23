import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../utils/error_handler.dart';
import 'storage_service.dart';

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
  reconnecting,
}

class WebSocketService {
  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  final String environmentId;
  
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<ConnectionStatus> _connectionController = 
      StreamController<ConnectionStatus>.broadcast();
  
  Stream<String> get output => _outputController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;
  
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  
  WebSocketService({required this.environmentId});

  Future<void> connect() async {
    if (_isDisposed) return;
    
    try {
      _logger.i('Connecting to WebSocket for environment: $environmentId');
      _connectionController.add(ConnectionStatus.connecting);
      
      final token = await StorageService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final uri = Uri.parse(
        '${AppConstants.wsBaseUrl}/api/v1/ws/terminal/$environmentId?token=$token'
      );
      
      _channel = WebSocketChannel.connect(uri);
      
      // Set up stream listener
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      _connectionController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      _logger.i('WebSocket connected successfully');
      
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'WebSocket connection failed',
        error: e,
        stackTrace: stackTrace,
        context: {'environmentId': environmentId},
      );
      
      _connectionController.add(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    if (_isDisposed) return;
    
    try {
      if (message is String) {
        final data = json.decode(message) as Map<String, dynamic>;
        
        switch (data['type']) {
          case 'output':
            if (data['data'] != null) {
              _outputController.add(data['data'] as String);
            }
            break;
            
          case 'error':
            final errorMessage = data['message'] ?? 'Terminal error occurred';
            _logger.w('Terminal error: $errorMessage');
            _outputController.add('\r\n\x1b[31mError: $errorMessage\x1b[0m\r\n');
            break;
            
          case 'status':
            _logger.d('Terminal status: ${data['message']}');
            break;
            
          case 'pong':
            // Heartbeat response - connection is alive
            break;
            
          default:
            _logger.d('Unknown message type: ${data['type']}');
        }
      } else {
        // Handle binary data if needed
        _outputController.add(message.toString());
      }
    } catch (e) {
      ErrorHandler.logError(
        'Failed to parse WebSocket message',
        error: e,
        context: {'message': message.toString()},
      );
    }
  }

  void _handleError(error) {
    if (_isDisposed) return;
    
    ErrorHandler.logError(
      'WebSocket error occurred',
      error: error,
      context: {'environmentId': environmentId},
    );
    
    _connectionController.add(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _handleDone() {
    if (_isDisposed) return;
    
    _logger.w('WebSocket connection closed');
    _connectionController.add(ConnectionStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) {
      if (_reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) {
        _logger.e('Max reconnection attempts reached');
        _outputController.add(
          '\r\n\x1b[31mConnection lost. Please refresh to reconnect.\x1b[0m\r\n'
        );
      }
      return;
    }
    
    _reconnectTimer?.cancel();
    _connectionController.add(ConnectionStatus.reconnecting);
    
    final delay = Duration(
      milliseconds: AppConstants.wsReconnectDelayMs * (_reconnectAttempts + 1),
    );
    _reconnectAttempts++;
    
    _logger.i('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inMilliseconds}ms');
    
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (!_isDisposed && _channel != null) {
          _sendMessage({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void sendCommand(String command) {
    if (_isDisposed || _channel == null) {
      _logger.w('Cannot send command: WebSocket not connected');
      return;
    }
    
    try {
      _sendMessage({
        'type': 'input',
        'data': command,
      });
      
      _logger.d('Sent command: ${command.replaceAll('\n', '\\n')}');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to send command',
        error: e,
        context: {'command': command},
      );
    }
  }

  void resize(int cols, int rows) {
    if (_isDisposed || _channel == null) return;
    
    try {
      _sendMessage({
        'type': 'resize',
        'cols': cols,
        'rows': rows,
      });
      
      _logger.d('Sent resize: ${cols}x$rows');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to send resize',
        error: e,
        context: {'cols': cols, 'rows': rows},
      );
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    final jsonMessage = json.encode(message);
    _channel?.sink.add(jsonMessage);
  }

  void disconnect() {
    if (_isDisposed) return;
    
    _logger.i('Disconnecting WebSocket');
    _isDisposed = true;
    
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    
    try {
      _channel?.sink.close(status.goingAway);
    } catch (e) {
      _logger.w('Error closing WebSocket', error: e);
    }
    
    // Close controllers
    _outputController.close();
    _connectionController.close();
    
    _logger.i('WebSocket disconnected');
  }

  // Utility methods
  bool get isConnected => 
      _channel != null && 
      !_isDisposed && 
      _connectionController.hasListener;

  bool get isReconnecting => 
      _reconnectTimer?.isActive == true;

  int get reconnectAttempts => _reconnectAttempts;

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
}