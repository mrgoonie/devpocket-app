import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../models/environment.dart';
import '../../models/enums.dart';
import '../../providers/environment_provider.dart';

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
  String _consoleLog = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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
                _isLoading = true;
                _consoleLog = '';
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
          
          window.flutter_inappwebview.callHandler('consoleLog', {
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
              
              // URL display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder, width: 1),
                  ),
                  child: Text(
                    _currentUrl ?? (environment?.externalUrl ?? 'No URL available'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText,
                      fontFamily: 'JetBrainsMono',
                    ),
                    overflow: TextOverflow.ellipsis,
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
        // Refresh
        IconButton(
          onPressed: _isLoading ? null : () => _webViewController?.reload(),
          icon: Icon(
            Icons.refresh,
            color: _isLoading ? AppTheme.mutedText : AppTheme.secondaryText,
            size: 20,
          ),
          tooltip: 'Refresh',
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
          tooltip: 'Developer Panel',
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
      height: 200,
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          top: BorderSide(color: AppTheme.neonGreen, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Panel header
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
                IconButton(
                  onPressed: () {
                    setState(() {
                      _consoleLog = '';
                    });
                  },
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _consoleLog.isEmpty 
                      ? 'Console output will appear here...'
                      : _consoleLog,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInExternalBrowser(String url) {
    // In a real implementation, you would use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Would open: $url'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
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