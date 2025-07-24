import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/environment_provider.dart';
import '../terminal/terminal_screen.dart';
import '../webview/webview_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/environment_selector.dart';
import '../../widgets/create_environment_sheet.dart';
import '../../models/enums.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<TabItem> _tabs = [
    TabItem(
      icon: Icons.terminal,
      label: 'Terminal',
      activeColor: AppTheme.neonGreen,
    ),
    TabItem(
      icon: Icons.web,
      label: 'Browser',
      activeColor: AppTheme.neonBlue,
    ),
    TabItem(
      icon: Icons.settings,
      label: 'Settings',
      activeColor: AppTheme.neonPink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, EnvironmentProvider>(
      builder: (context, authProvider, environmentProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(authProvider, environmentProvider),

                // Environment Selector
                if (environmentProvider.environments.isNotEmpty)
                  _buildEnvironmentSelector(environmentProvider),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      TerminalScreen(),
                      WebViewScreen(),
                      SettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Bottom Navigation
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
    );
  }

  Widget _buildTopBar(
      AuthProvider authProvider, EnvironmentProvider environmentProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkBorder, width: 2),
        ),
      ),
      child: Row(
        children: [
          // App Title
          Text(
            'DevPocket',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _tabs[_currentIndex].activeColor,
                  fontWeight: FontWeight.w900,
                ),
          ).animate().shimmer(
              duration: 2.seconds,
              color: _tabs[_currentIndex].activeColor.withValues(alpha: 0.3)),

          const Spacer(),

          // Connection Status
          _buildConnectionStatus(environmentProvider),

          const SizedBox(width: 12),

          // Refresh Button
          IconButton(
            onPressed: environmentProvider.isLoading
                ? null
                : () => environmentProvider.fetchEnvironments(),
            icon: Icon(
              Icons.refresh,
              color: environmentProvider.isLoading
                  ? AppTheme.mutedText
                  : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(EnvironmentProvider environmentProvider) {
    final currentEnv = environmentProvider.currentEnvironment;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (currentEnv == null) {
      statusColor = AppTheme.mutedText;
      statusText = 'No Environment';
      statusIcon = Icons.circle_outlined;
    } else {
      switch (currentEnv.status) {
        case EnvironmentStatus.running:
          statusColor = AppTheme.successColor;
          statusText = 'Connected';
          statusIcon = Icons.circle;
          break;
        case EnvironmentStatus.creating:
          statusColor = AppTheme.warningColor;
          statusText = 'Starting...';
          statusIcon = Icons.circle_outlined;
          break;
        case EnvironmentStatus.stopped:
          statusColor = AppTheme.errorColor;
          statusText = 'Disconnected';
          statusIcon = Icons.circle_outlined;
          break;
        case EnvironmentStatus.terminated:
          statusColor = AppTheme.errorColor;
          statusText = 'Terminated';
          statusIcon = Icons.circle_outlined;
          break;
        case EnvironmentStatus.error:
          statusColor = AppTheme.errorColor;
          statusText = 'Error';
          statusIcon = Icons.error_outline;
          break;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusIcon,
          size: 12,
          color: statusColor,
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(
            duration: 2.seconds, color: statusColor.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentSelector(EnvironmentProvider environmentProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkBorder, width: 1),
        ),
      ),
      child: EnvironmentSelector(
        environments: environmentProvider.environments,
        currentEnvironment: environmentProvider.currentEnvironment,
        onEnvironmentChanged: (environment) {
          environmentProvider.setCurrentEnvironment(environment);
        },
        onCreateNew: () => _showCreateEnvironmentDialog(environmentProvider),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          top: BorderSide(color: AppTheme.darkBorder, width: 2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = index == _currentIndex;

          return Tab(
            height: 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? tab.activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isActive
                    ? Border.all(color: tab.activeColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 24,
                    color: isActive
                        ? tab.activeColor
                        : AppTheme.primaryText.withValues(alpha: 0.7),
                  ).animate(target: isActive ? 1 : 0).scale(duration: 200.ms),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? tab.activeColor
                          : AppTheme.primaryText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        labelPadding: EdgeInsets.zero,
        indicator: const BoxDecoration(),
        dividerColor: Colors.transparent,
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
}

class TabItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  TabItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
