import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/environment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/loading/loading_screen.dart';
import 'screens/main/main_screen.dart';
import 'utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.logError(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };
  
  runApp(const DevPocketApp());
}

class DevPocketApp extends StatelessWidget {
  const DevPocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EnvironmentProvider()),
      ],
      child: MaterialApp(
        title: 'DevPocket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppInitializer(),
        builder: (context, child) {
          // Add error boundary
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return _buildErrorWidget(details);
          };
          return child!;
        },
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please restart the app and try again.',
                style: TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // In a real app, you might want to restart or report the error
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _logger.i('Initializing DevPocket app...');
      
      // Add any additional initialization here
      // For example: checking for app updates, initializing analytics, etc.
      
      _logger.i('App initialization completed');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        'App initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (!authProvider.isInitialized) {
          return const LoadingScreen(
            message: 'Initializing DevPocket...',
          );
        }

        // Show error state if needed
        if (authProvider.error != null && !authProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Failed to initialize',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.clearError();
                        _initializeApp();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Navigate based on authentication state
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}