# Kiến trúc Flutter App - K8s Terminal

## 1. App Structure

```
lib/
├── main.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── terminal/
│   │   ├── terminal_screen.dart
│   │   └── terminal_controller.dart
│   └── webview/
│       └── webview_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── websocket_service.dart
│   └── k8s_service.dart
├── models/
│   ├── user.dart
│   ├── deployment.dart
│   └── terminal_session.dart
└── widgets/
    ├── terminal_widget.dart
    └── tab_navigation.dart
```

## 2. Core Components

### Terminal Widget
```dart
import 'package:xterm/xterm.dart';

class TerminalWidget extends StatefulWidget {
  final String podName;
  final String namespace;
  
  @override
  _TerminalWidgetState createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  late Terminal terminal;
  late TerminalController controller;
  WebSocketChannel? _channel;
  
  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 10000);
    controller = TerminalController();
    _connectToServer();
  }
  
  void _connectToServer() {
    // WebSocket URL: wss://api.yourserver.com/ws/exec/{namespace}/{pod}
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.yourserver.com/ws/exec/${widget.namespace}/${widget.podName}')
    );
    
    // Listen to WebSocket messages
    _channel!.stream.listen((data) {
      terminal.write(data);
    });
    
    // Send terminal input to server
    terminal.onOutput = (data) {
      _channel!.sink.add(data);
    };
  }
}
```

### WebSocket Service
```dart
class WebSocketService {
  static const String WS_BASE_URL = 'wss://api.yourserver.com';
  WebSocketChannel? _channel;
  
  Future<void> connectToPod(String namespace, String podName, String container) async {
    final token = await AuthService.getToken();
    
    final wsUrl = Uri.parse(
      '$WS_BASE_URL/ws/exec/$namespace/$podName?container=$container&token=$token'
    );
    
    _channel = WebSocketChannel.connect(wsUrl);
  }
  
  Stream<String> get stream => _channel!.stream.cast<String>();
  
  void sendCommand(String command) {
    _channel?.sink.add(command);
  }
  
  void dispose() {
    _channel?.sink.close();
  }
}
```

## 3. Tab Navigation

```dart
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          TerminalScreen(),
          WebViewScreen(url: 'https://your-app-preview.com'),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.terminal), text: 'Terminal'),
          Tab(icon: Icon(Icons.web), text: 'Preview'),
        ],
      ),
    );
  }
}
```

## 4. State Management với Provider

```dart
class DeploymentProvider extends ChangeNotifier {
  Deployment? _currentDeployment;
  bool _isLoading = false;
  
  Future<void> createDeployment() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await K8sService.createDeployment();
      _currentDeployment = Deployment.fromJson(response);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void connectToTerminal() {
    if (_currentDeployment != null) {
      WebSocketService().connectToPod(
        _currentDeployment!.namespace,
        _currentDeployment!.podName,
        'main',
      );
    }
  }
}
```