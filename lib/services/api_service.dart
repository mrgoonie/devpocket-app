import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:logger/logger.dart';
import '../models/environment.dart';
import '../models/metrics_response.dart';
import '../models/template.dart';
import '../models/resource_limits.dart';
import '../config/constants.dart';
import '../utils/error_handler.dart';
import 'auth_service.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: AppConstants.apiBaseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Environment endpoints
  @GET('/api/v1/environments/')
  Future<List<Environment>> getEnvironments();

  @POST('/api/v1/environments/')
  Future<Environment> createEnvironment(
      @Body() CreateEnvironmentRequest request);

  @GET('/api/v1/environments/{id}')
  Future<Environment> getEnvironment(@Path('id') String id);

  @PUT('/api/v1/environments/{id}')
  Future<Environment> updateEnvironment(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/v1/environments/{id}')
  Future<void> deleteEnvironment(@Path('id') String id);

  @POST('/api/v1/environments/{id}/start')
  Future<void> startEnvironment(@Path('id') String id);

  @POST('/api/v1/environments/{id}/stop')
  Future<void> stopEnvironment(@Path('id') String id);

  @POST('/api/v1/environments/{id}/restart')
  Future<void> restartEnvironment(@Path('id') String id);

  @GET('/api/v1/environments/{id}/metrics')
  Future<MetricsResponse> getEnvironmentMetrics(@Path('id') String id);

  @GET('/api/v1/environments/{id}/logs')
  Future<LogsResponse> getEnvironmentLogs(
    @Path('id') String id,
    @Query('lines') int? lines,
    @Query('since') String? since,
  );

  // Template endpoints
  @GET('/api/v1/templates/')
  Future<List<Template>> getTemplates();

  @GET('/api/v1/templates/{id}')
  Future<TemplateResponse> getTemplate(@Path('id') String id);
}

class ApiManager {
  static final Logger _logger = Logger();
  late final Dio _dio;
  late final ApiService _apiService;

  ApiManager() {
    _dio = Dio();
    _setupInterceptors();
    _apiService = ApiService(_dio);
  }

  void _setupInterceptors() {
    // Add auth interceptor (reusing from auth_service.dart)
    _dio.interceptors.add(AuthInterceptor());

    // Add error handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final appError = ErrorHandler.handleError(error);
        ErrorHandler.logError(
          'API Error: ${error.requestOptions.path}',
          error: appError,
          context: {
            'method': error.requestOptions.method,
            'path': error.requestOptions.path,
            'statusCode': error.response?.statusCode,
          },
        );
        handler.next(error);
      },
    ));

    // Add logging interceptor for debug builds
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) {
        // Only log essential info, not full request/response details
        if (obj.toString().contains('ERROR') ||
            obj.toString().contains('FAIL')) {
          _logger.e(obj.toString());
        }
      },
    ));

    // Set timeout configuration
    _dio.options.connectTimeout =
        const Duration(milliseconds: AppConstants.connectTimeoutMs);
    _dio.options.receiveTimeout =
        const Duration(milliseconds: AppConstants.receiveTimeoutMs);
  }

  // Environment operations
  Future<List<Environment>> getEnvironments() async {
    try {
      _logger.d('Fetching environments');
      final environments = await _apiService.getEnvironments();
      _logger.d('Fetched ${environments.length} environments');
      return environments;
    } catch (e) {
      ErrorHandler.logError('Failed to fetch environments', error: e);
      rethrow;
    }
  }

  Future<Environment> createEnvironment({
    required String name,
    required String templateId,
    ResourceLimits? resourceLimits,
    Map<String, String>? environmentVariables,
  }) async {
    try {
      _logger.i('Creating environment: $name with template: $templateId');

      final request = CreateEnvironmentRequest(
        name: name,
        templateId: templateId,
        resourceLimits: resourceLimits,
        environmentVariables: environmentVariables,
      );

      final environment = await _apiService.createEnvironment(request);
      _logger.i('Created environment: ${environment.id}');
      return environment;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to create environment',
        error: e,
        context: {'name': name, 'templateId': templateId},
      );
      rethrow;
    }
  }

  Future<Environment> getEnvironment(String id) async {
    try {
      _logger.d('Fetching environment: $id');
      final environment = await _apiService.getEnvironment(id);
      return environment;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to fetch environment',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<Environment> updateEnvironment(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      _logger.i('Updating environment: $id');
      final environment = await _apiService.updateEnvironment(id, updates);
      _logger.i('Updated environment: $id');
      return environment;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to update environment',
        error: e,
        context: {'id': id, 'updates': updates},
      );
      rethrow;
    }
  }

  Future<void> deleteEnvironment(String id) async {
    try {
      _logger.i('Deleting environment: $id');
      await _apiService.deleteEnvironment(id);
      _logger.i('Deleted environment: $id');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to delete environment',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<void> startEnvironment(String id) async {
    try {
      _logger.i('Starting environment: $id');
      await _apiService.startEnvironment(id);
      _logger.i('Started environment: $id');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to start environment',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<void> stopEnvironment(String id) async {
    try {
      _logger.i('Stopping environment: $id');
      await _apiService.stopEnvironment(id);
      _logger.i('Stopped environment: $id');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to stop environment',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<void> restartEnvironment(String id) async {
    try {
      _logger.i('Restarting environment: $id');
      await _apiService.restartEnvironment(id);
      _logger.i('Restarted environment: $id');
    } catch (e) {
      ErrorHandler.logError(
        'Failed to restart environment',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<MetricsResponse> getEnvironmentMetrics(String id) async {
    try {
      _logger.d('Fetching metrics for environment: $id');
      final metrics = await _apiService.getEnvironmentMetrics(id);
      return metrics;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to fetch environment metrics',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }

  Future<LogsResponse> getEnvironmentLogs(
    String id, {
    int? lines,
    String? since,
  }) async {
    try {
      _logger.d('Fetching logs for environment: $id');
      final logs = await _apiService.getEnvironmentLogs(id, lines, since);
      return logs;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to fetch environment logs',
        error: e,
        context: {'id': id, 'lines': lines, 'since': since},
      );
      rethrow;
    }
  }

  // Template operations
  Future<List<Template>> getTemplates() async {
    try {
      _logger.d('Fetching templates');
      final templates = await _apiService.getTemplates();
      _logger.d('Fetched ${templates.length} templates');
      return templates;
    } catch (e) {
      ErrorHandler.logError('Failed to fetch templates', error: e);
      rethrow;
    }
  }

  Future<TemplateResponse> getTemplate(String id) async {
    try {
      _logger.d('Fetching template: $id');
      final template = await _apiService.getTemplate(id);
      return template;
    } catch (e) {
      ErrorHandler.logError(
        'Failed to fetch template',
        error: e,
        context: {'id': id},
      );
      rethrow;
    }
  }
}
