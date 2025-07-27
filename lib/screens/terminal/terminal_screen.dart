import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final FocusNode _inputFocusNode = FocusNode();
  String? _currentEnvironmentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _terminalProvider = context.read<TerminalProvider>();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
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
    
    // Get access token
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
                  _terminalProvider.clearTerminal();
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
                        : _buildTerminalOutput(),
              ),
              
              // Command Input (only show when environment is running)
              if (currentEnvironment?.status == EnvironmentStatus.running)
                _buildCommandInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerminalOutput() {
    return Consumer<TerminalProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            controller: provider.scrollController,
            itemCount: provider.outputLines.length,
            itemBuilder: (context, index) {
              final line = provider.outputLines[index];
              return SelectableText(
                line,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  color: Color(0xFF00FF41), // Neon green
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommandInput() {
    return Consumer<TerminalProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[700]!),
            ),
          ),
          child: Row(
            children: [
              const Text(
                '\$ ',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 16,
                  color: Color(0xFF00FF41),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: provider.inputController,
                  focusNode: _inputFocusNode,
                  enabled: provider.isConnected,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
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
                icon: const Icon(Icons.send, color: Color(0xFF00FF41)),
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