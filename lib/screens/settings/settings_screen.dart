import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/environment_provider.dart';
import '../../widgets/brutalist_button.dart';
import '../../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<AuthProvider, EnvironmentProvider>(
      builder: (context, authProvider, environmentProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // User Profile Section
                  _buildUserProfileSection(user)
                      .animate()
                      .fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Environment Stats Section
                  _buildEnvironmentStatsSection(environmentProvider)
                      .animate()
                      .fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Account Settings
                  _buildSettingsSection(
                    'Account Settings',
                    [
                      _buildSettingItem(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'Manage your personal information',
                        onTap: () => _showProfileDialog(user),
                      ),
                      _buildSettingItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () => _showChangePasswordDialog(authProvider),
                      ),
                      _buildSettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Configure notification preferences',
                        onTap: () => _showNotificationsDialog(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),

                  // Subscription & Billing
                  _buildSettingsSection(
                    'Subscription & Billing',
                    [
                      _buildSettingItem(
                        icon: Icons.workspace_premium,
                        title: 'Current Plan',
                        subtitle:
                            user?.subscriptionPlan.toUpperCase() ?? 'FREE',
                        trailing: user?.subscriptionPlan != 'free'
                            ? const Icon(Icons.star,
                                color: AppTheme.neonYellow, size: 20)
                            : null,
                        onTap: () => _showSubscriptionDialog(user),
                      ),
                      _buildSettingItem(
                        icon: Icons.payment,
                        title: 'Billing',
                        subtitle: 'Manage billing and payment methods',
                        onTap: () => _showBillingDialog(),
                      ),
                      _buildSettingItem(
                        icon: Icons.history,
                        title: 'Usage History',
                        subtitle: 'View your environment usage statistics',
                        onTap: () => _showUsageHistoryDialog(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 24),

                  // App Settings
                  _buildSettingsSection(
                    'App Settings',
                    [
                      _buildSettingItem(
                        icon: Icons.terminal,
                        title: 'Terminal Settings',
                        subtitle: 'Customize terminal appearance and behavior',
                        onTap: () => _showTerminalSettingsDialog(),
                      ),
                      _buildSettingItem(
                        icon: Icons.storage,
                        title: 'Storage',
                        subtitle: 'Manage local data and cache',
                        onTap: () => _showStorageDialog(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms),

                  const SizedBox(height: 24),

                  // Support & Legal
                  _buildSettingsSection(
                    'Support & Legal',
                    [
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support',
                        onTap: () => _showSupportDialog(),
                      ),
                      _buildSettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: () => _showPrivacyPolicyDialog(),
                      ),
                      _buildSettingItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms of service',
                        onTap: () => _showTermsDialog(),
                      ),
                      _buildSettingItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'App version and information',
                        onTap: () => _showAboutDialog(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1200.ms),

                  const SizedBox(height: 32),

                  // Sign Out Button
                  _buildSignOutButton(authProvider)
                      .animate()
                      .fadeIn(delay: 1400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.neonPink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neonPink, width: 2),
          ),
          child: const Icon(
            Icons.settings,
            color: AppTheme.neonPink,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.neonPink,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              'Manage your account and preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfileSection(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonGreen, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.primaryBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.neonGreen, width: 2),
            ),
            child: Center(
              child: Text(
                user?.username.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? user?.username ?? 'Unknown User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSubscriptionColor(user?.subscriptionPlan),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (user?.subscriptionPlan ?? 'free').toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentStatsSection(
      EnvironmentProvider environmentProvider) {
    final totalEnvs = environmentProvider.environments.length;
    final runningEnvs = environmentProvider.runningEnvironments.length;
    final stoppedEnvs = environmentProvider.stoppedEnvironments.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonBlue, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.primaryBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_outlined,
                color: AppTheme.neonBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Environment Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.neonBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total',
                  value: totalEnvs.toString(),
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Running',
                  value: runningEnvs.toString(),
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Stopped',
                  value: stoppedEnvs.toString(),
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder, width: 2),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  item,
                  if (!isLast)
                    const Divider(
                      color: AppTheme.darkBorder,
                      height: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.secondaryText,
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
            ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: AppTheme.mutedText,
            size: 20,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSignOutButton(AuthProvider authProvider) {
    return Center(
      child: BrutalistButton(
        onPressed: authProvider.isLoading
            ? null
            : () => _showSignOutDialog(authProvider),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: AppTheme.primaryWhite,
        isLoading: authProvider.isLoading,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text('SIGN OUT'),
          ],
        ),
      ),
    );
  }

  Color _getSubscriptionColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'pro':
        return AppTheme.neonPurple;
      case 'starter':
        return AppTheme.neonYellow;
      case 'free':
      default:
        return AppTheme.mutedText;
    }
  }

  // Dialog methods
  void _showProfileDialog(User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Profile',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Profile management coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Change Password',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Password change coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Notifications',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Notification settings coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Subscription',
            style: TextStyle(color: AppTheme.primaryText)),
        content: Text(
          'Current plan: ${(user?.subscriptionPlan ?? 'free').toUpperCase()}\n\nSubscription management coming soon!',
          style: const TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showBillingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Billing',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Billing management coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showUsageHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Usage History',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Usage statistics coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showTerminalSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Terminal Settings',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Terminal customization coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Storage',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Storage management coming soon!',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Support',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'For support, please contact:\nsupport@devpocket.io',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Privacy Policy',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Privacy Policy will be available at:\nhttps://devpocket.io/privacy',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Terms of Service',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Terms of Service will be available at:\nhttps://devpocket.io/terms',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('About DevPocket',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'DevPocket v1.0.0\n\nThe mobile-first cloud IDE.\nCode anywhere, anytime.\n\nBuilt with ❤️ in Vietnam',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Sign Out',
            style: TextStyle(color: AppTheme.primaryText)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
