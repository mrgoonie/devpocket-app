import 'dart:async';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../models/terminal_message.dart';

class TerminalProvider extends ChangeNotifier {
  final WebSocketTerminalService _wsService = WebSocketTerminalService();
  
  final List<String> _outputLines = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Stream for direct terminal data (for xterm integration)
  final StreamController<String> _terminalDataController = StreamController.broadcast();
  
  ConnectionStatus _connectionState = ConnectionStatus.disconnected;
  String? _currentEnvironmentId;
  Map<String, dynamic>? _environmentInfo;
  
  // Getters
  List<String> get outputLines => List.unmodifiable(_outputLines);
  TextEditingController get inputController => _inputController;
  ScrollController get scrollController => _scrollController;
  ConnectionStatus get connectionState => _connectionState;
  String? get currentEnvironmentId => _currentEnvironmentId;
  Map<String, dynamic>? get environmentInfo => _environmentInfo;
  
  bool get isConnected => _connectionState == ConnectionStatus.connected;
  bool get isConnecting => _connectionState == ConnectionStatus.connecting;
  
  // Stream for xterm integration
  Stream<String> get terminalDataStream => _terminalDataController.stream;
  
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
      print('TerminalProvider received message: ${message.type} - ${message.data}');
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
    
    // For xterm integration, we don't add output lines
    // The welcome message is sent directly to terminal via stream
    final welcomeText = '\x1b[32m🎉 ${message.data}\x1b[0m\r\n';
    _terminalDataController.add(welcomeText);
    
    if (_environmentInfo != null) {
      final envInfo = '\x1b[36mEnvironment: ${_environmentInfo!['name']} (${_environmentInfo!['template']})\x1b[0m\r\n';
      _terminalDataController.add(envInfo);
    }
    
    notifyListeners();
  }
  
  void _handleOutputMessage(TerminalMessage message) {
    // For xterm integration, stream raw data directly to terminal
    _terminalDataController.add(message.data);
  }
  
  void _handleErrorMessage(TerminalMessage message) {
    // For xterm integration, stream error directly to terminal
    final errorText = '\x1b[31m❌ Error: ${message.data}\x1b[0m\r\n';
    _terminalDataController.add(errorText);
  }
  
  // Connect to environment
  Future<bool> connectToEnvironment(String environmentId, String accessToken) async {
    _currentEnvironmentId = environmentId;
    
    final success = await _wsService.connect(environmentId, accessToken);
    
    if (!success) {
      final errorText = '\x1b[31m❌ Failed to connect to environment\x1b[0m\r\n';
      _terminalDataController.add(errorText);
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
  
  // Send direct input for xterm integration
  void sendDirectInput(String data) {
    if (!isConnected) return;
    _wsService.sendRawInput(data);
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
        duration: const Duration(milliseconds: 300),
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
    _terminalDataController.close();
    super.dispose();
  }
}