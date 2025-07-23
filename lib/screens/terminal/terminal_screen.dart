import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../config/theme.dart';
import '../../providers/environment_provider.dart';
import '../../services/websocket_service.dart';
import '../../widgets/brutalist_button.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen>
    with AutomaticKeepAliveClientMixin {
  Terminal? _terminal;
  TerminalController? _terminalController;
  WebSocketService? _webSocketService;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _currentEnvironmentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTerminal();
    });
  }

  @override
  void dispose() {
    _webSocketService?.disconnect();
    _terminal?.buffer.clear();
    super.dispose();
  }

  void _initializeTerminal() {
    _terminal = Terminal(
      maxLines: AppConstants.terminalMaxLines,
    );
    
    _terminalController = TerminalController();
    
    // Handle terminal input
    _terminal!.onOutput = (data) {
      _webSocketService?.sendCommand(data);
    };
    
    // Handle terminal resize
    _terminal!.onResize = (width, height) {
      _webSocketService?.resize(width, height);
    };
    
    // Connect to current environment if available
    final environmentProvider = context.read<EnvironmentProvider>();
    if (environmentProvider.currentEnvironment != null) {
      _connectToEnvironment(environmentProvider.currentEnvironment!.id);
    }
  }

  void _connectToEnvironment(String environmentId) {
    if (_currentEnvironmentId == environmentId && 
        _webSocketService?.isConnected == true) {
      return; // Already connected to this environment
    }

    // Disconnect from previous environment
    _webSocketService?.disconnect();
    
    // Clear terminal
    _terminal?.buffer.clear();
    _terminal?.write('\x1b[2J\x1b[H'); // Clear screen and move cursor to top
    
    _currentEnvironmentId = environmentId;
    
    // Create new WebSocket connection
    _webSocketService = WebSocketService(environmentId: environmentId);
    
    // Listen to WebSocket output
    _webSocketService!.output.listen((data) {
      _terminal?.write(data);
    });
    
    // Listen to connection status
    _webSocketService!.connectionStatus.listen((status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    });
    
    // Connect to WebSocket
    _webSocketService!.connect();
    
    // Show connection message
    _terminal?.write('\x1b[32mConnecting to environment: $environmentId\x1b[0m\r\n');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<EnvironmentProvider>(
      builder: (context, environmentProvider, child) {
        final currentEnvironment = environmentProvider.currentEnvironment;
        
        // Auto-connect when environment changes
        if (currentEnvironment != null && 
            currentEnvironment.id != _currentEnvironmentId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _connectToEnvironment(currentEnvironment.id);
          });
        }
        
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Column(
            children: [
              // Terminal Header
              _buildTerminalHeader(currentEnvironment),
              
              // Terminal Content
              Expanded(
                child: currentEnvironment == null
                    ? _buildNoEnvironmentState(environmentProvider)
                    : currentEnvironment.status != 'running'
                        ? _buildEnvironmentNotRunningState(
                            currentEnvironment, environmentProvider)
                        : _buildTerminalView(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerminalHeader(Environment? environment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Terminal icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonGreen, width: 2),
            ),
            child: const Icon(
              Icons.terminal,
              color: AppTheme.neonGreen,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Environment info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  environment?.name ?? 'No Environment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  environment != null 
                      ? 'Template: ${environment.template}'
                      : 'Select an environment to start coding',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          // Connection status
          _buildConnectionIndicator(),
          
          const SizedBox(width: 12),
          
          // Actions
          _buildTerminalActions(environment),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    Color color;
    String tooltip;
    IconData icon;
    
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        color = AppTheme.successColor;
        tooltip = 'Connected';
        icon = Icons.circle;
        break;
      case ConnectionStatus.connecting:
        color = AppTheme.warningColor;
        tooltip = 'Connecting...';
        icon = Icons.circle_outlined;
        break;
      case ConnectionStatus.reconnecting:
        color = AppTheme.warningColor;
        tooltip = 'Reconnecting...';
        icon = Icons.refresh;
        break;
      case ConnectionStatus.disconnected:
        color = AppTheme.mutedText;
        tooltip = 'Disconnected';
        icon = Icons.circle_outlined;
        break;
      case ConnectionStatus.error:
        color = AppTheme.errorColor;
        tooltip = 'Connection Error';
        icon = Icons.error_outline;
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildTerminalActions(Environment? environment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clear terminal
        IconButton(
          onPressed: () {
            _terminal?.buffer.clear();
            _terminal?.write('\x1b[2J\x1b[H');
          },
          icon: const Icon(
            Icons.clear_all,
            color: AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Clear Terminal',
        ),
        
        // Reconnect
        if (_connectionStatus == ConnectionStatus.error ||
            _connectionStatus == ConnectionStatus.disconnected)
          IconButton(
            onPressed: environment != null
                ? () => _connectToEnvironment(environment.id)
                : null,
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.neonBlue,
              size: 20,
            ),
            tooltip: 'Reconnect',
          ),
      ],
    );
  }

  Widget _buildNoEnvironmentState(EnvironmentProvider environmentProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: AppTheme.mutedText,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Environment Selected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Create or select an environment to start coding',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            BrutalistButton(
              onPressed: () => _showCreateEnvironmentDialog(environmentProvider),
              child: const Text('CREATE ENVIRONMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentNotRunningState(
    Environment environment,
    EnvironmentProvider environmentProvider,
  ) {
    String statusMessage;
    String actionMessage;
    Color statusColor;
    
    switch (environment.status) {
      case 'starting':
        statusMessage = 'Environment is starting up...';
        actionMessage = 'Please wait while your environment boots up';
        statusColor = AppTheme.warningColor;
        break;
      case 'stopping':
        statusMessage = 'Environment is shutting down...';
        actionMessage = 'Please wait for the shutdown to complete';
        statusColor = AppTheme.warningColor;
        break;
      case 'stopped':
        statusMessage = 'Environment is stopped';
        actionMessage = 'Start your environment to begin coding';
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusMessage = 'Environment is ${environment.status}';
        actionMessage = 'Please check the environment status';
        statusColor = AppTheme.mutedText;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_settings_new,
              size: 64,
              color: statusColor,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              actionMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            if (environment.status == 'stopped')
              BrutalistButton(
                onPressed: environmentProvider.isLoading
                    ? null
                    : () => _startEnvironment(environmentProvider, environment.id),
                isLoading: environmentProvider.isLoading,
                child: const Text('START ENVIRONMENT'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView() {
    if (_terminal == null || _terminalController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.neonGreen,
        ),
      );
    }
    
    return Container(
      color: AppTheme.terminalTheme['background'],
      child: TerminalView(
        _terminal!,
        controller: _terminalController!,
        textStyle: const TerminalStyle(
          fontSize: 14,
          fontFamily: 'JetBrainsMono',
        ),
        theme: TerminalTheme(
          cursor: AppTheme.terminalTheme['cursor']!,
          selection: AppTheme.terminalTheme['selection']!,
          foreground: AppTheme.terminalTheme['foreground']!,
          background: AppTheme.terminalTheme['background']!,
          black: AppTheme.terminalTheme['black']!,
          red: AppTheme.terminalTheme['red']!,
          green: AppTheme.terminalTheme['green']!,
          yellow: AppTheme.terminalTheme['yellow']!,
          blue: AppTheme.terminalTheme['blue']!,
          magenta: AppTheme.terminalTheme['magenta']!,
          cyan: AppTheme.terminalTheme['cyan']!,
          white: AppTheme.terminalTheme['white']!,
          brightBlack: AppTheme.terminalTheme['brightBlack']!,
          brightRed: AppTheme.terminalTheme['brightRed']!,
          brightGreen: AppTheme.terminalTheme['brightGreen']!,
          brightYellow: AppTheme.terminalTheme['brightYellow']!,
          brightBlue: AppTheme.terminalTheme['brightBlue']!,
          brightMagenta: AppTheme.terminalTheme['brightMagenta']!,
          brightCyan: AppTheme.terminalTheme['brightCyan']!,
          brightWhite: AppTheme.terminalTheme['brightWhite']!,
        ),
      ),
    );
  }

  void _showCreateEnvironmentDialog(EnvironmentProvider environmentProvider) {
    // This would typically show the same dialog as in main_screen.dart
    // For now, just show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the environment selector above to create a new environment'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _startEnvironment(EnvironmentProvider environmentProvider, String id) async {
    try {
      await environmentProvider.startEnvironment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Environment started successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start environment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}