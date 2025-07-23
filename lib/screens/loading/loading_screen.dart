import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

class LoadingScreen extends StatefulWidget {
  final String? message;
  final String? environmentName;
  final VoidCallback? onCancel;

  const LoadingScreen({
    super.key,
    this.message,
    this.environmentName,
    this.onCancel,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _containerController;
  late AnimationController _pulseController;
  late AnimationController _codeController;
  
  late Animation<double> _containerRotation;
  late Animation<double> _pulseScale;
  late Animation<Offset> _codeSlide;

  final List<String> _loadingMessages = [
    'Spinning up container...',
    'Pulling Docker image...',
    'Configuring environment...',
    'Installing dependencies...',
    'Setting up workspace...',
    'Almost ready...',
  ];

  final List<String> _codeSnippets = [
    'FROM ubuntu:latest',
    'RUN apt-get update',
    'COPY . /workspace',
    'WORKDIR /workspace',
    'RUN npm install',
    'EXPOSE 3000',
    'CMD ["npm", "start"]',
  ];

  int _currentMessageIndex = 0;
  int _currentCodeIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Container animation (spinning Docker container)
    _containerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _containerRotation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: Curves.linear,
    ));
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Code animation
    _codeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _codeSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _codeController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _containerController.repeat();
    _pulseController.repeat(reverse: true);
    
    // Cycle through messages and code
    _startMessageCycle();
    _startCodeCycle();
  }

  void _startMessageCycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _startMessageCycle();
      }
    });
  }

  void _startCodeCycle() {
    _codeController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _codeController.reset();
          setState(() {
            _currentCodeIndex = (_currentCodeIndex + 1) % _codeSnippets.length;
          });
          _startCodeCycle();
        }
      });
    });
  }

  @override
  void dispose() {
    _containerController.dispose();
    _pulseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              if (widget.onCancel != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DevPocket',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ] else ...[
                const SizedBox(height: 60),
              ],
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main container animation
                    _buildAnimatedContainer(),
                    
                    const SizedBox(height: 60),
                    
                    // Environment name
                    if (widget.environmentName != null) ...[
                      Text(
                        'Setting up ${widget.environmentName}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 20),
                    ],
                    
                    // Loading message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        widget.message ?? _loadingMessages[_currentMessageIndex],
                        key: ValueKey(_currentMessageIndex),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Progress indicator
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 60),
                    
                    // Code snippet area
                    _buildCodeArea(),
                  ],
                ),
              ),
              
              // Tips at bottom
              _buildTips().animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_containerController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseScale.value,
          child: Transform.rotate(
            angle: _containerRotation.value * 2 * 3.14159,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.neonBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlack,
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.primaryBlack,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.developer_mode,
                size: 60,
                color: AppTheme.primaryBlack,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.darkBorder,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonPink),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This usually takes 30-60 seconds',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonGreen,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.primaryBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.warningColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Text(
                'Dockerfile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SlideTransition(
            position: _codeSlide,
            child: Text(
              _codeSnippets[_currentCodeIndex],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neonGreen,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.neonYellow,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Your environment will be ready in moments. You can start coding as soon as it loads!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}