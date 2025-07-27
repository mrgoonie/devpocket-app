import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../models/terminal_message.dart';

class TerminalProvider extends ChangeNotifier {
  final WebSocketTerminalService _wsService = WebSocketTerminalService();
  
  final List<String> _outputLines = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
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
    super.dispose();
  }
}