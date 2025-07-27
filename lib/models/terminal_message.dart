enum TerminalMessageType {
  welcome,
  output,
  error,
  pong,
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