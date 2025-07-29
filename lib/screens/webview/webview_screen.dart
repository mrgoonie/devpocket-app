import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/environment.dart';
import '../../models/enums.dart';
import '../../providers/environment_provider.dart';

class ConsoleLogEntry {
  final String level;
  final String message;
  final DateTime timestamp;

  ConsoleLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  Color get levelColor {
    switch (level) {
      case 'error':
        return AppTheme.errorColor;
      case 'warn':
        return AppTheme.warningColor;
      case 'info':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryText;
    }
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String? _currentUrl;
  bool _showDevPanel = false;
  final List<ConsoleLogEntry> _consoleLogs = [];
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _jsController = TextEditingController();
  bool _isEditingUrl = false;
  String _logFilter = 'all'; // all, log, error, warn, info

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _jsController.dispose();
    super.dispose();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _urlController.text = url;
                _isLoading = true;
                _consoleLogs.clear();
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _injectConsoleCapture();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar('Failed to load page: ${error.description}');
          },
        ),
      );
  }

  void _injectConsoleCapture() {
    if (_webViewController == null) return;

    // Inject JavaScript to capture console logs
    _webViewController!.runJavaScript('''
      (function() {
        const originalLog = console.log;
        const originalError = console.error;
        const originalWarn = console.warn;
        const originalInfo = console.info;
        
        function sendToFlutter(level, args) {
          const message = Array.from(args).map(arg => {
            if (typeof arg === 'object') {
              try {
                return JSON.stringify(arg, null, 2);
              } catch (e) {
                return String(arg);
              }
            }
            return String(arg);
          }).join(' ');
          
          // Store logs in window object for Flutter to access
          if (!window._flutterLogs) window._flutterLogs = [];
          window._flutterLogs.push({
            level: level,
            message: message,
            timestamp: new Date().toISOString()
          });
        }
        
        console.log = function() {
          originalLog.apply(console, arguments);
          sendToFlutter('log', arguments);
        };
        
        console.error = function() {
          originalError.apply(console, arguments);
          sendToFlutter('error', arguments);
        };
        
        console.warn = function() {
          originalWarn.apply(console, arguments);
          sendToFlutter('warn', arguments);
        };
        
        console.info = function() {
          originalInfo.apply(console, arguments);
          sendToFlutter('info', arguments);
        };
        
        // Capture uncaught errors
        window.addEventListener('error', function(e) {
          sendToFlutter('error', [e.message + ' at ' + e.filename + ':' + e.lineno]);
        });
        
        // Capture unhandled promise rejections
        window.addEventListener('unhandledrejection', function(e) {
          sendToFlutter('error', ['Unhandled Promise Rejection:', e.reason]);
        });
      })();
    ''');

    // Poll for new logs periodically
    _startLogPolling();
  }

  void _startLogPolling() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _webViewController == null) {
        timer.cancel();
        return;
      }
      
      _fetchConsoleLogsFromJS();
    });
  }

  Future<void> _fetchConsoleLogsFromJS() async {
    try {
      final result = await _webViewController!.runJavaScriptReturningResult('''
        (function() {
          if (!window._flutterLogs) return "[]";
          const logs = JSON.stringify(window._flutterLogs);
          window._flutterLogs = []; // Clear after reading
          return logs;
        })();
      ''');

      if (result.toString() != '[]' && result.toString() != 'null') {
        final String logsJson = result.toString().replaceAll('"', '"').replaceAll('"', '"');
        final List<dynamic> logsList = jsonDecode(logsJson);
        
        setState(() {
          for (final logData in logsList) {
            _consoleLogs.add(ConsoleLogEntry(
              level: logData['level'] as String,
              message: logData['message'] as String,
              timestamp: DateTime.parse(logData['timestamp'] as String),
            ));
          }
        });
      }
    } catch (e) {
      // Silently ignore errors to avoid spam
    }
  }

  void _navigateToUrl(String url) {
    if (_webViewController == null) return;

    // Ensure URL has a protocol
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    _webViewController!.loadRequest(Uri.parse(finalUrl));
    setState(() {
      _isEditingUrl = false;
    });
  }

  void _onUrlSubmitted(String url) {
    if (url.trim().isNotEmpty) {
      _navigateToUrl(url.trim());
    }
  }

  Future<void> _goBack() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
    }
  }

  Future<void> _goForward() async {
    if (_webViewController != null && await _webViewController!.canGoForward()) {
      await _webViewController!.goForward();
    }
  }

  Future<void> _reloadPage() async {
    if (_webViewController != null) {
      await _webViewController!.reload();
    }
  }

  void _clearConsole() {
    setState(() {
      _consoleLogs.clear();
    });
  }

  Future<void> _executeJavaScript(String script) async {
    if (_webViewController != null && script.trim().isNotEmpty) {
      try {
        await _webViewController!.runJavaScript(script);
        _jsController.clear();
      } catch (e) {
        _showErrorSnackBar('JavaScript execution error: $e');
      }
    }
  }

  List<ConsoleLogEntry> get _filteredLogs {
    if (_logFilter == 'all') return _consoleLogs;
    return _consoleLogs.where((log) => log.level == _logFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<EnvironmentProvider>(
      builder: (context, environmentProvider, child) {
        final currentEnvironment = environmentProvider.currentEnvironment;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Column(
            children: [
              // WebView Header
              _buildWebViewHeader(currentEnvironment),

              // WebView Content
              Expanded(
                child: currentEnvironment == null
                    ? _buildNoEnvironmentState()
                    : currentEnvironment.status != EnvironmentStatus.running
                        ? _buildEnvironmentNotRunningState(currentEnvironment)
                        : _buildWebViewContent(),
              ),

              // Developer Panel
              if (_showDevPanel) _buildDeveloperPanel(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebViewHeader(Environment? environment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Browser icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.neonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.neonBlue, width: 2),
                ),
                child: const Icon(
                  Icons.web,
                  color: AppTheme.neonBlue,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // URL input/display
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingUrl = true;
                      _urlController.text = _currentUrl ?? environment?.externalUrl ?? '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isEditingUrl ? AppTheme.neonBlue : AppTheme.darkBorder,
                        width: _isEditingUrl ? 2 : 1,
                      ),
                    ),
                    child: _isEditingUrl
                        ? TextField(
                            controller: _urlController,
                            autofocus: true,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryText,
                                  fontFamily: 'JetBrainsMono',
                                ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter URL...',
                              hintStyle: TextStyle(
                                color: AppTheme.mutedText,
                                fontFamily: 'JetBrainsMono',
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: _onUrlSubmitted,
                            onTapOutside: (_) {
                              setState(() {
                                _isEditingUrl = false;
                              });
                            },
                          )
                        : Text(
                            _currentUrl ?? environment?.externalUrl ?? 'No URL available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontFamily: 'JetBrainsMono',
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Actions
              _buildWebViewActions(environment),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              backgroundColor: AppTheme.darkCard,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebViewActions(Environment? environment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button
        IconButton(
          onPressed: _isLoading ? null : _goBack,
          icon: Icon(
            Icons.arrow_back,
            color: _isLoading ? AppTheme.mutedText : AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Back',
        ),

        // Forward button
        IconButton(
          onPressed: _isLoading ? null : _goForward,
          icon: Icon(
            Icons.arrow_forward,
            color: _isLoading ? AppTheme.mutedText : AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Forward',
        ),

        // Refresh
        IconButton(
          onPressed: _isLoading ? null : _reloadPage,
          icon: Icon(
            Icons.refresh,
            color: _isLoading ? AppTheme.mutedText : AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Reload',
        ),

        // Developer panel toggle
        IconButton(
          onPressed: () {
            setState(() {
              _showDevPanel = !_showDevPanel;
            });
          },
          icon: Icon(
            _showDevPanel ? Icons.code_off : Icons.code,
            color: _showDevPanel ? AppTheme.neonGreen : AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Developer Console',
        ),

        // External browser
        IconButton(
          onPressed: _currentUrl != null
              ? () => _openInExternalBrowser(_currentUrl!)
              : null,
          icon: const Icon(
            Icons.open_in_new,
            color: AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Open in Browser',
        ),
      ],
    );
  }

  Widget _buildNoEnvironmentState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.web,
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
              'Select an environment to preview your application',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentNotRunningState(Environment environment) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.power_settings_new,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Environment Not Running',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your environment to preview your application',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewContent() {
    return WebViewWidget(controller: _webViewController!);
  }

  Widget _buildDeveloperPanel() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          top: BorderSide(color: AppTheme.neonGreen, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Panel header with controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(
                bottom: BorderSide(color: AppTheme.darkBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: AppTheme.neonGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Developer Console',
                  style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                
                // Log filter dropdown
                DropdownButton<String>(
                  value: _logFilter,
                  onChanged: (value) {
                    setState(() {
                      _logFilter = value!;
                    });
                  },
                  dropdownColor: AppTheme.darkSurface,
                  underline: Container(),
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 10,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'log', child: Text('Log')),
                    DropdownMenuItem(value: 'error', child: Text('Error')),
                    DropdownMenuItem(value: 'warn', child: Text('Warn')),
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Clear console button
                IconButton(
                  onPressed: _clearConsole,
                  icon: const Icon(
                    Icons.clear,
                    color: AppTheme.secondaryText,
                    size: 16,
                  ),
                  tooltip: 'Clear Console',
                ),
              ],
            ),
          ),

          // Console output
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: _filteredLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'Console output will appear here...',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${log.level.toUpperCase()}]',
                                style: TextStyle(
                                  color: log.levelColor,
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: const TextStyle(
                                    color: AppTheme.primaryText,
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // JavaScript execution input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(
                top: BorderSide(color: AppTheme.darkBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '> ',
                  style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _jsController,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Execute JavaScript...',
                      hintStyle: TextStyle(
                        color: AppTheme.mutedText,
                        fontFamily: 'JetBrainsMono',
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _executeJavaScript,
                  ),
                ),
                IconButton(
                  onPressed: () => _executeJavaScript(_jsController.text),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.neonGreen,
                    size: 16,
                  ),
                  tooltip: 'Execute',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInExternalBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open URL: $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening URL: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
