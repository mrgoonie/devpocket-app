import 'dart:async';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import '../models/auth_response.dart';
import '../models/token.dart';
import '../models/user.dart';
import '../models/error_response.dart';
import '../config/constants.dart';
import 'storage_service.dart';

part 'auth_service.g.dart';

@RestApi(baseUrl: AppConstants.apiBaseUrl)
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST('/api/v1/auth/register')
  Future<Token> register(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/login')
  Future<Token> login(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/google')
  Future<Token> googleSignIn(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/refresh')
  Future<Token> refreshToken(@Body() Map<String, dynamic> body);

  @GET('/api/v1/auth/me')
  Future<User> getProfile();

  @POST('/api/v1/auth/logout')
  Future<void> logout();

  @POST('/api/v1/auth/change-password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/forgot-password')
  Future<void> forgotPassword(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/reset-password')
  Future<void> resetPassword(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/verify-email')
  Future<void> verifyEmail(@Body() Map<String, dynamic> body);

  @POST('/api/v1/auth/resend-verification')
  Future<void> resendVerificationEmail();

  @PUT('/api/v1/users/me')
  Future<User> updateProfile(@Body() Map<String, dynamic> body);

  @DELETE('/api/v1/users/me')
  Future<void> deleteAccount();

  @GET('/api/v1/health')
  Future<Map<String, dynamic>> healthCheck();
}

class AuthInterceptor extends Interceptor {
  static final _logger = Logger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token != null && !_isTokenExpired(token)) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.d('Added auth token to request: ${options.path}');
      } else {
        _logger.w('No valid token available for request: ${options.path}');
      }
    } catch (e) {
      _logger.w('Failed to add auth token to request', error: e);
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _logger.w('Received 401 error, attempting token refresh');

      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null && !_isTokenExpired(refreshToken)) {
        try {
          final dio = Dio();
          final response = await dio.post(
            '${AppConstants.apiBaseUrl}/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          final token = Token.fromJson(response.data);
          await StorageService.saveTokens(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
          );

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] =
              'Bearer ${token.accessToken}';

          final cloneReq = await dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );

          _logger.i('Successfully refreshed token and retried request');
          return handler.resolve(cloneReq);
        } catch (refreshError) {
          _logger.e('Token refresh failed', error: refreshError);
          await StorageService.clearAll();
        }
      } else {
        _logger.w('No valid refresh token available');
        await StorageService.clearAll();
      }
    }
    super.onError(err, handler);
  }

  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      _logger.w('Failed to decode JWT token', error: e);
      return true;
    }
  }
}

class AuthManager {
  static final _logger = Logger();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // iOS client ID from GoogleService-Info.plist
    clientId:
        '331656256423-gfjk0ohtpjtnvad19c6mdeeisnuiqeg7.apps.googleusercontent.com',
  );

  late final Dio _dio;
  late final AuthService _authService;

  AuthManager() {
    _dio = Dio();
    _setupInterceptors();
    _authService = AuthService(_dio);
  }

  void _setupInterceptors() {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        // Only log essential info, not full request/response details
        if (obj.toString().contains('ERROR') ||
            obj.toString().contains('FAIL')) {
          _logger.e(obj.toString());
        }
      },
    ));

    // Add timeout configuration
    _dio.options.connectTimeout =
        const Duration(milliseconds: AppConstants.connectTimeoutMs);
    _dio.options.receiveTimeout =
        const Duration(milliseconds: AppConstants.receiveTimeoutMs);
  }

  Future<AuthResponse> login(String usernameOrEmail, String password) async {
    try {
      _logger.i('Attempting login for: $usernameOrEmail');
      final tokenResponse = await _authService.login({
        'username_or_email': usernameOrEmail.trim(),
        'password': password,
      });

      // Save tokens
      await StorageService.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Fetch user profile
      final user = await _authService.getProfile();
      await StorageService.saveUser(user);

      // Create AuthResponse for compatibility
      final authResponse = AuthResponse(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        tokenType: tokenResponse.tokenType,
        expiresIn: tokenResponse.expiresIn,
        user: user,
      );

      _logger.i('Login successful');
      return authResponse;
    } catch (e) {
      _logger.e('Login failed', error: e);

      // Enhanced error handling for login
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = _extractErrorMessage(e);

        if (statusCode == 401) {
          if (errorMessage.toLowerCase().contains('incorrect')) {
            throw Exception(
                'Invalid credentials. Please check your username/email and password. If you just registered, please wait a moment and try again.');
          } else {
            throw Exception(
                'Authentication failed. Please verify your credentials and try again.');
          }
        } else if (statusCode == 404) {
          throw Exception(
              'User not found. Please check your username/email or register for a new account.');
        } else if (statusCode == 429) {
          throw Exception(
              'Too many login attempts. Please wait a few minutes and try again.');
        }
      }

      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _logger.i('Attempting registration for email: $email');
      final tokenResponse = await _authService.register({
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        if (fullName != null && fullName.isNotEmpty)
          'full_name': fullName.trim(),
      });

      // Save tokens
      await StorageService.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Fetch user profile
      final user = await _authService.getProfile();
      await StorageService.saveUser(user);

      // Create AuthResponse for compatibility
      final authResponse = AuthResponse(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        tokenType: tokenResponse.tokenType,
        expiresIn: tokenResponse.expiresIn,
        user: user,
      );

      _logger.i('Registration successful');
      return authResponse;
    } catch (e) {
      _logger.e('Registration failed', error: e);

      // Enhanced error handling for registration
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final errorMessage = _extractErrorMessage(e);

        if (statusCode == 500) {
          // Server error - could be user created but response failed
          if (errorMessage.toLowerCase().contains('could not create user') ||
              errorMessage.toLowerCase().contains('duplicate') ||
              errorMessage.toLowerCase().contains('already exists')) {
            throw Exception(
                'Registration may have succeeded but there was a server error. Please try logging in with your credentials, or try a different username/email if the account already exists.');
          } else {
            throw Exception(
                'Server error during registration. Please try again or contact support if the issue persists.');
          }
        } else if (statusCode == 409) {
          // Conflict - user already exists
          throw Exception(
              'An account with this username or email already exists. Please try logging in or use different credentials.');
        } else if (statusCode == 400) {
          // Bad request - validation error
          throw Exception(
              'Invalid registration data. Please check your input and try again.');
        }
      }

      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      _logger.i('Attempting Google Sign-In');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final tokenResponse = await _authService.googleSignIn({
        'id_token': googleAuth.idToken!,
        'access_token': googleAuth.accessToken,
      });

      // Save tokens
      await StorageService.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Fetch user profile
      final user = await _authService.getProfile();
      await StorageService.saveUser(user);

      // Create AuthResponse for compatibility
      final authResponse = AuthResponse(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        tokenType: tokenResponse.tokenType,
        expiresIn: tokenResponse.expiresIn,
        user: user,
      );

      _logger.i('Google Sign-In successful');
      return authResponse;
    } catch (e) {
      _logger.e('Google Sign-In failed', error: e);
      await _googleSignIn.signOut(); // Clean up on failure
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      _logger.i('Google Sign-Out successful');
    } catch (e) {
      _logger.w('Google Sign-Out failed', error: e);
    }
  }

  Future<User> getProfile() async {
    try {
      final user = await _authService.getProfile();
      await StorageService.saveUser(user);
      return user;
    } catch (e) {
      _logger.e('Failed to get user profile', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('Attempting logout');
      await _authService.logout();
    } catch (e) {
      _logger.w('Logout request failed', error: e);
    } finally {
      await StorageService.clearAll();
      await signOutGoogle();
      _logger.i('Logout completed');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword({
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      _logger.i('Password changed successfully');
    } catch (e) {
      _logger.e('Password change failed', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword({
        'email': email.trim(),
      });
      _logger.i('Password reset email sent');
    } catch (e) {
      _logger.e('Forgot password failed', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPassword({
        'token': token,
        'new_password': newPassword,
      });
      _logger.i('Password reset successful');
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> verifyEmail(String verificationCode) async {
    try {
      _logger.i('Attempting email verification');
      await _authService.verifyEmail({
        'token': verificationCode,
      });
      _logger.i('Email verification successful');
    } catch (e) {
      _logger.e('Email verification failed', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      _logger.i('Attempting to resend verification email');
      await _authService.resendVerificationEmail();
      _logger.i('Verification email resent successfully');
    } catch (e) {
      _logger.e('Failed to resend verification email', error: e);
      throw await _handleErrorWithConnectivityCheck(e);
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return false;

      if (JwtDecoder.isExpired(token)) {
        _logger.i('Access token expired, checking refresh token');
        final refreshToken = await StorageService.getRefreshToken();
        if (refreshToken == null || JwtDecoder.isExpired(refreshToken)) {
          await StorageService.clearAll();
          return false;
        }
        // Try to refresh the token
        try {
          final tokenResponse = await _authService.refreshToken({
            'refresh_token': refreshToken,
          });
          await StorageService.saveTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
          );
          return true;
        } catch (e) {
          await StorageService.clearAll();
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.e('Authentication check failed', error: e);
      return false;
    }
  }

  String _extractErrorMessage(DioException error) {
    try {
      final response = error.response;
      if (response?.data is Map<String, dynamic>) {
        final errorResponse = ErrorResponse.fromJson(response!.data);
        return errorResponse.detail;
      }
    } catch (e) {
      // Fallback to generic message
    }
    return 'Server error occurred';
  }

  // Helper method to check server connectivity
  Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get(
        '${AppConstants.apiBaseUrl}/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.w('Server health check failed', error: e);
      return false;
    }
  }

  // Enhanced error handler with connectivity check
  Future<Exception> _handleErrorWithConnectivityCheck(dynamic error) async {
    if (error is DioException) {
      // Check for connection errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        // Check if it's a localhost connection issue
        if (AppConstants.apiBaseUrl.contains('localhost')) {
          return Exception(
              'Cannot connect to local server. Please make sure your development server is running on ${AppConstants.apiBaseUrl}');
        } else {
          final isServerUp = await checkServerHealth();
          if (!isServerUp) {
            return Exception(
                'Server is not responding. Please check your internet connection or try again later.');
          }
        }
        return Exception(
            'Connection timeout. Please check your network connection and try again.');
      }
    }

    return _handleError(error);
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response?.data is Map<String, dynamic>) {
        try {
          final errorResponse = ErrorResponse.fromJson(response!.data);
          // For specific error messages, provide more user-friendly feedback
          String detail = errorResponse.detail;
          if (detail.toLowerCase().contains('could not create user')) {
            detail =
                'Unable to create account. The username or email might already be taken.';
          } else if (detail.toLowerCase().contains('duplicate')) {
            detail = 'An account with this username or email already exists.';
          } else if (detail.toLowerCase().contains('validation')) {
            detail = 'Please check your input and try again.';
          }
          return Exception(detail);
        } catch (e) {
          // Fallback to generic error handling
        }
      }

      switch (error.response?.statusCode) {
        case 400:
          return Exception('Invalid request. Please check your input.');
        case 401:
          return Exception('Invalid credentials. Please try again.');
        case 403:
          return Exception('Access forbidden. Please contact support.');
        case 404:
          return Exception('Service not found. Please try again later.');
        case 429:
          return Exception('Too many requests. Please try again later.');
        case 500:
          // Check if this is a specific registration error
          if (response?.data is Map<String, dynamic>) {
            final data = response!.data as Map<String, dynamic>;
            if (data['detail']
                    ?.toString()
                    .toLowerCase()
                    .contains('could not create user') ==
                true) {
              return Exception(
                  'Unable to create account. The username or email might already be taken.');
            }
          }
          return Exception('Server error. Please try again later.');
        default:
          return Exception('Network error. Please check your connection.');
      }
    }

    return Exception('An unexpected error occurred. Please try again.');
  }
}
