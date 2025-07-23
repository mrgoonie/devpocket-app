import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brutalist_button.dart';
import '../../widgets/brutalist_text_field.dart';
import '../../config/theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo and Title
                    _buildHeader().animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                    
                    const SizedBox(height: 60),
                    
                    // Email Field
                    BrutalistTextField(
                      controller: _emailController,
                      label: 'Email or Username',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or username';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.3),
                    
                    const SizedBox(height: 20),
                    
                    // Password Field
                    BrutalistTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.secondaryText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.3),
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    BrutalistButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      isLoading: authProvider.isLoading,
                      child: const Text('SIGN IN'),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: 20),
                    
                    // Or Divider
                    _buildOrDivider().animate().fadeIn(delay: 800.ms, duration: 600.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Google Sign In Button
                    BrutalistButton(
                      onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                      backgroundColor: AppTheme.primaryWhite,
                      foregroundColor: AppTheme.primaryBlack,
                      isLoading: authProvider.isLoading,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google.png',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text('CONTINUE WITH GOOGLE'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Link
                    _buildSignUpLink().animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Forgot Password Link
                    _buildForgotPasswordLink().animate().fadeIn(delay: 1400.ms, duration: 600.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neonGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.primaryBlack,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.terminal,
            size: 48,
            color: AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'DevPocket',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppTheme.neonGreen,
            fontWeight: FontWeight.black,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Code anywhere, anytime',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.darkBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.darkBorder)),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Sign Up',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.neonPink,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: Implement forgot password
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forgot password feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.neonBlue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}