import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../models/error_response.dart';

class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final ErrorType type;

  AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    required this.type,
  });

  @override
  String toString() {
    return 'AppError: $message (Type: $type, Code: $code)';
  }
}

enum ErrorType {
  network,
  authentication,
  authorization,
  validation,
  server,
  client,
  unknown,
  websocket,
  storage,
}

class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    _logger.e('Handling error', error: error, stackTrace: stackTrace);

    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return AppError(
        message: 'Invalid data format: ${error.message}',
        type: ErrorType.client,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TypeError) {
      return AppError(
        message: 'Type error occurred. Please try again.',
        type: ErrorType.client,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Handle common Flutter/Dart exceptions
    if (error is StateError) {
      return AppError(
        message: 'Application state error. Please restart the app.',
        type: ErrorType.client,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return AppError(
        message: 'Invalid argument provided.',
        type: ErrorType.client,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // WebSocket errors
    if (error.toString().contains('WebSocket')) {
      return AppError(
        message: 'Connection lost. Attempting to reconnect...',
        type: ErrorType.websocket,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Storage errors
    if (error.toString().contains('storage') || 
        error.toString().contains('Storage')) {
      return AppError(
        message: 'Failed to access device storage. Please check permissions.',
        type: ErrorType.storage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic error handling
    return AppError(
      message: error.toString().isNotEmpty 
          ? error.toString() 
          : 'An unexpected error occurred',
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static AppError _handleDioError(DioException error) {
    final response = error.response;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please check your internet connection.',
          type: ErrorType.network,
          code: 'TIMEOUT',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return AppError(
          message: 'No internet connection. Please check your network.',
          type: ErrorType.network,
          code: 'NO_CONNECTION',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(response!);

      case DioExceptionType.cancel:
        return AppError(
          message: 'Request was cancelled.',
          type: ErrorType.client,
          code: 'CANCELLED',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return AppError(
          message: 'Network error occurred. Please try again.',
          type: ErrorType.network,
          originalError: error,
        );
    }
  }

  static AppError _handleHttpError(Response response) {
    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    
    // Try to parse error response
    String message;
    String? code;
    
    if (data is Map<String, dynamic>) {
      try {
        final errorResponse = ErrorResponse.fromJson(data);
        message = errorResponse.detail;
        code = errorResponse.code;
      } catch (e) {
        // Fallback to generic messages based on status code
        message = _getMessageForStatusCode(statusCode);
      }
    } else {
      message = _getMessageForStatusCode(statusCode);
    }

    ErrorType type;
    switch (statusCode) {
      case 400:
        type = ErrorType.validation;
        break;
      case 401:
        type = ErrorType.authentication;
        break;
      case 403:
        type = ErrorType.authorization;
        break;
      case 404:
        type = ErrorType.client;
        break;
      case 422:
        type = ErrorType.validation;
        break;
      case 429:
        type = ErrorType.client;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        type = ErrorType.server;
        break;
      default:
        type = ErrorType.unknown;
    }

    return AppError(
      message: message,
      code: code ?? statusCode.toString(),
      type: type,
      originalError: response,
    );
  }

  static String _getMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please sign in to continue.';
      case 403:
        return 'You don\'t have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. The resource may already exist.';
      case 422:
        return 'The provided data is invalid.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again.';
      case 503:
        return 'Service is currently under maintenance.';
      case 504:
        return 'Service timeout. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final contextString = context != null 
        ? '\nContext: ${context.toString()}' 
        : '';
    
    _logger.e(
      '$message$contextString',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logWarning(
    String message, {
    dynamic error,
    Map<String, dynamic>? context,
  }) {
    final contextString = context != null 
        ? '\nContext: ${context.toString()}' 
        : '';
    
    _logger.w('$message$contextString', error: error);
  }

  static void logInfo(
    String message, {
    Map<String, dynamic>? context,
  }) {
    final contextString = context != null 
        ? '\nContext: ${context.toString()}' 
        : '';
    
    _logger.i('$message$contextString');
  }

  static void logDebug(
    String message, {
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      final contextString = context != null 
          ? '\nContext: ${context.toString()}' 
          : '';
      
      _logger.d('$message$contextString');
    }
  }

  static String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Please sign in again to continue.';
      case ErrorType.authorization:
        return 'You don\'t have permission to perform this action.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.server:
        return 'Our servers are experiencing issues. Please try again later.';
      case ErrorType.websocket:
        return 'Connection lost. Attempting to reconnect...';
      case ErrorType.storage:
        return 'Unable to access device storage. Please check app permissions.';
      case ErrorType.client:
      case ErrorType.unknown:
        return error.message;
    }
  }

  static bool isRetryableError(AppError error) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.server:
      case ErrorType.websocket:
        return true;
      case ErrorType.authentication:
      case ErrorType.authorization:
      case ErrorType.validation:
      case ErrorType.client:
      case ErrorType.storage:
      case ErrorType.unknown:
        return false;
    }
  }
}