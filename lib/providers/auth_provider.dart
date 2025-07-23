import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AuthManager _authManager = AuthManager();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  
  AuthProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      _setLoading(true);
      
      // Check if user is already authenticated
      final isAuth = await _authManager.isAuthenticated();
      if (isAuth) {
        // Get user data from storage first
        _user = await StorageService.getUser();
        
        // Try to get fresh user data from API
        try {
          final freshUser = await _authManager.getProfile();
          _user = freshUser;
        } catch (e) {
          _logger.w('Failed to fetch fresh user data, using cached data', error: e);
          // If we can't get fresh data but have cached data, that's fine
          if (_user == null) {
            // If no cached data either, clear everything
            await _authManager.logout();
            _user = null;
          }
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to initialize auth provider', error: e);
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authManager.login(email, password);
      _user = response.user;
      
      _logger.i('User logged in successfully: ${_user?.email}');
      notifyListeners();
    } catch (e) {
      _logger.e('Login failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authManager.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      _user = response.user;
      
      _logger.i('User registered successfully: ${_user?.email}');
      notifyListeners();
    } catch (e) {
      _logger.e('Registration failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _authManager.signInWithGoogle();
      _user = response.user;
      
      _logger.i('User signed in with Google successfully: ${_user?.email}');
      notifyListeners();
    } catch (e) {
      _logger.e('Google sign-in failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authManager.logout();
      _user = null;
      
      _logger.i('User logged out successfully');
      notifyListeners();
    } catch (e) {
      _logger.e('Logout failed', error: e);
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> refreshUserProfile() async {
    if (!isAuthenticated) return;
    
    try {
      final freshUser = await _authManager.getProfile();
      _user = freshUser;
      notifyListeners();
      _logger.i('User profile refreshed successfully');
    } catch (e) {
      _logger.e('Failed to refresh user profile', error: e);
      _setError(e.toString());
    }
  }
  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authManager.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _logger.i('Password changed successfully');
    } catch (e) {
      _logger.e('Password change failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authManager.forgotPassword(email);
      _logger.i('Password reset email sent');
    } catch (e) {
      _logger.e('Forgot password failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authManager.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      
      _logger.i('Password reset successfully');
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  void clearError() {
    _setError(null);
  }
  
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }
  
  void _setError(String? value) {
    if (_error != value) {
      _error = value;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}