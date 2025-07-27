import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../config/theme.dart';
import '../../models/environment.dart';
import '../../models/enums.dart';
import '../../providers/environment_provider.dart';
import '../../providers/terminal_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/brutalist_button.dart';
import '../../widgets/create_environment_sheet.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen>
    with AutomaticKeepAliveClientMixin {
  late TerminalProvider _terminalProvider;
  Terminal? _terminal;
  TerminalController? _terminalController;
  String? _currentEnvironmentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _terminalProvider = context.read<TerminalProvider>();
    _initializeTerminal();
  }

  void _initializeTerminal() {
    _terminal = Terminal(
      maxLines: 10000,
    );
    
    _terminalController = TerminalController();
    
    // Handle terminal input directly - send raw input to WebSocket
    _terminal!.onOutput = (data) {
      _terminalProvider.sendRawInput(data);
    };
    
    // Handle terminal resize
    _terminal!.onResize = (width, height, pixelWidth, pixelHeight) {
      _terminalProvider.resizeTerminal(width, height);
    };
    
    // Listen to WebSocket output and write to terminal
    _terminalProvider.terminalDataStream.listen((data) {
      _terminal?.write(data);
    });
  }

  @override
  void dispose() {
    _terminal?.buffer.clear();
    super.dispose();
  }

  Future<void> _connectToEnvironmentIfNeeded(Environment environment) async {
    if (_currentEnvironmentId == environment.id && _terminalProvider.isConnected) {
      return; // Already connected
    }

    if (environment.status != EnvironmentStatus.running) {
      return; // Environment not running
    }

    _currentEnvironmentId = environment.id;
    
    // Clear terminal 
    _terminal?.buffer.clear();
    
    // Get access token and connect
    final accessToken = await StorageService.getAccessToken();
    if (accessToken != null) {
      await _terminalProvider.connectToEnvironment(environment.id, accessToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<EnvironmentProvider, TerminalProvider>(
      builder: (context, environmentProvider, terminalProvider, child) {
        final currentEnvironment = environmentProvider.currentEnvironment;

        // Auto-connect when environment changes
        if (currentEnvironment != null &&
            currentEnvironment.id != _currentEnvironmentId &&
            currentEnvironment.status == EnvironmentStatus.running) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _connectToEnvironmentIfNeeded(currentEnvironment);
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            title: Text(
              currentEnvironment != null 
                ? 'Terminal - ${currentEnvironment.name}' 
                : 'Terminal',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              // Connection status indicator
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
                    onPressed: () async {
                      if (!provider.isConnected && currentEnvironment != null) {
                        final accessToken = await StorageService.getAccessToken();
                        if (accessToken != null) {
                          provider.connectToEnvironment(
                            currentEnvironment.id,
                            accessToken,
                          );
                        }
                      }
                    },
                  );
                },
              ),
              // Clear terminal button
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _terminal?.buffer.clear();
                  _terminal?.write('\x1b[2J\x1b[H'); // Clear screen and move cursor to top
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Connection Status Banner
              Consumer<TerminalProvider>(
                builder: (context, provider, child) {
                  if (provider.isConnecting) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.orange,
                      child: const Text(
                        '🔌 Connecting to terminal...',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!provider.isConnected && currentEnvironment?.status == EnvironmentStatus.running) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red,
                      child: const Text(
                        '❌ Disconnected - Tap cloud icon to reconnect',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Main content area
              Expanded(
                child: currentEnvironment == null
                    ? _buildNoEnvironmentState(environmentProvider)
                    : currentEnvironment.status != EnvironmentStatus.running
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

  Widget _buildTerminalView() {
    if (_terminal == null || _terminalController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.neonGreen,
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: TerminalView(
        _terminal!,
        controller: _terminalController!,
        autofocus: true,
        textStyle: const TerminalStyle(
          fontSize: 14,
          fontFamily: 'JetBrainsMono',
        ),
        theme: TerminalTheme(
          cursor: const Color(0xFF00FF41),
          selection: const Color(0xFF444444),
          foreground: const Color(0xFF00FF41),
          background: Colors.black,
          black: Colors.black,
          red: const Color(0xFFFF0000),
          green: const Color(0xFF00FF41),
          yellow: const Color(0xFFFFFF00),
          blue: const Color(0xFF0000FF),
          magenta: const Color(0xFFFF00FF),
          cyan: const Color(0xFF00FFFF),
          white: Colors.white,
          brightBlack: const Color(0xFF555555),
          brightRed: const Color(0xFFFF5555),
          brightGreen: const Color(0xFF55FF55),
          brightYellow: const Color(0xFFFFFF55),
          brightBlue: const Color(0xFF5555FF),
          brightMagenta: const Color(0xFFFF55FF),
          brightCyan: const Color(0xFF55FFFF),
          brightWhite: Colors.white,
          searchHitBackground: const Color(0xFFFFFF00),
          searchHitBackgroundCurrent: const Color(0xFFFFAA00),
          searchHitForeground: Colors.black,
        ),
      ),
    );
  }

  Widget _buildNoEnvironmentState(EnvironmentProvider environmentProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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
      case EnvironmentStatus.creating:
        statusMessage = 'Environment is starting up...';
        actionMessage = 'Please wait while your environment boots up';
        statusColor = AppTheme.warningColor;
        break;
      case EnvironmentStatus.stopped:
        statusMessage = 'Environment is stopped';
        actionMessage = 'Start your environment to begin coding';
        statusColor = AppTheme.errorColor;
        break;
      case EnvironmentStatus.terminated:
        statusMessage = 'Environment is terminated';
        actionMessage = 'Please restart your environment';
        statusColor = AppTheme.errorColor;
        break;
      case EnvironmentStatus.error:
        statusMessage = 'Environment has an error';
        actionMessage = 'Please check the environment status';
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusMessage = 'Environment is ${environment.status.name}';
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
            if (environment.status == EnvironmentStatus.stopped)
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

  void _showCreateEnvironmentDialog(EnvironmentProvider environmentProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateEnvironmentSheet(
        environmentProvider: environmentProvider,
      ),
    );
  }

  void _startEnvironment(
      EnvironmentProvider environmentProvider, String id) async {
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
        final errorMessage = environmentProvider.error ?? 'Failed to start environment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}