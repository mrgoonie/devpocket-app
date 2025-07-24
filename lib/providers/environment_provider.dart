import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/environment.dart';
import '../models/template.dart';
import '../models/metrics_response.dart';
import '../models/resource_limits.dart';
import '../models/enums.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';

class EnvironmentProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final ApiManager _apiManager = ApiManager();

  List<Environment> _environments = [];
  Environment? _currentEnvironment;
  List<Template> _templates = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;

  // Getters
  List<Environment> get environments => _environments;
  Environment? get currentEnvironment => _currentEnvironment;
  List<Template> get templates => _templates;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;

  // Filter environments by status
  List<Environment> get runningEnvironments => _environments
      .where((env) => env.status == EnvironmentStatus.running)
      .toList();

  List<Environment> get stoppedEnvironments => _environments
      .where((env) => env.status == EnvironmentStatus.stopped)
      .toList();

  EnvironmentProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchEnvironments();
    await fetchTemplates();
  }

  Future<void> fetchEnvironments() async {
    _setLoading(true);
    _setError(null);

    try {
      _logger.d('Fetching environments');
      _environments = await _apiManager.getEnvironments();
      _logger.d('Fetched ${_environments.length} environments');
      notifyListeners();
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to fetch environments', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTemplates() async {
    try {
      _logger.i('Fetching templates');
      _templates = await _apiManager.getTemplates();
      _logger.i('Fetched ${_templates.length} templates');
      notifyListeners();
    } catch (e) {
      ErrorHandler.logError('Failed to fetch templates', error: e);
      // Don't set error for templates as it's not critical
    }
  }

  Future<void> createEnvironment({
    required String name,
    required String templateId,
    ResourceLimits? resourceLimits,
    Map<String, String>? environmentVariables,
  }) async {
    _setCreating(true);
    _setError(null);

    try {
      _logger.i('Creating environment: $name');

      final environment = await _apiManager.createEnvironment(
        name: name,
        templateId: templateId,
        resourceLimits: resourceLimits,
        environmentVariables: environmentVariables,
      );

      _environments.insert(0, environment); // Add to top
      _currentEnvironment = environment;

      _logger.i('Environment created: ${environment.id}');
      notifyListeners();
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to create environment', error: e);
      rethrow;
    } finally {
      _setCreating(false);
    }
  }

  Future<void> startEnvironment(String id) async {
    _setError(null);

    try {
      _logger.i('Starting environment: $id');

      // Optimistically update UI
      _updateEnvironmentStatus(id, EnvironmentStatus.running);

      await _apiManager.startEnvironment(id);

      // Fetch fresh data to get actual status
      await _refreshEnvironment(id);

      _logger.i('Environment started: $id');
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to start environment', error: e);

      // Revert optimistic update
      await _refreshEnvironment(id);
      rethrow;
    }
  }

  Future<void> stopEnvironment(String id) async {
    _setError(null);

    try {
      _logger.i('Stopping environment: $id');

      // Optimistically update UI
      _updateEnvironmentStatus(id, EnvironmentStatus.stopped);

      await _apiManager.stopEnvironment(id);

      // Fetch fresh data to get actual status
      await _refreshEnvironment(id);

      _logger.i('Environment stopped: $id');
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to stop environment', error: e);

      // Revert optimistic update
      await _refreshEnvironment(id);
      rethrow;
    }
  }

  Future<void> restartEnvironment(String id) async {
    _setError(null);

    try {
      _logger.i('Restarting environment: $id');

      // Optimistically update UI
      _updateEnvironmentStatus(id, EnvironmentStatus.running);

      await _apiManager.restartEnvironment(id);

      // Fetch fresh data to get actual status
      await _refreshEnvironment(id);

      _logger.i('Environment restarted: $id');
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to restart environment', error: e);

      // Revert optimistic update
      await _refreshEnvironment(id);
      rethrow;
    }
  }

  Future<void> deleteEnvironment(String id) async {
    _setError(null);

    try {
      _logger.i('Deleting environment: $id');

      await _apiManager.deleteEnvironment(id);

      // Remove from local list
      _environments.removeWhere((env) => env.id == id);

      // Clear current environment if it was deleted
      if (_currentEnvironment?.id == id) {
        _currentEnvironment = null;
      }

      _logger.i('Environment deleted: $id');
      notifyListeners();
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      _setError(ErrorHandler.getUserFriendlyMessage(appError));
      ErrorHandler.logError('Failed to delete environment', error: e);
      rethrow;
    }
  }

  Future<void> refreshEnvironment(String id) async {
    await _refreshEnvironment(id);
  }

  Future<void> _refreshEnvironment(String id) async {
    try {
      final environment = await _apiManager.getEnvironment(id);

      // Update in the list
      final index = _environments.indexWhere((env) => env.id == id);
      if (index != -1) {
        _environments[index] = environment;
      }

      // Update current environment if it matches
      if (_currentEnvironment?.id == id) {
        _currentEnvironment = environment;
      }

      notifyListeners();
    } catch (e) {
      ErrorHandler.logError('Failed to refresh environment', error: e);
    }
  }

  void _updateEnvironmentStatus(String id, EnvironmentStatus status) {
    final index = _environments.indexWhere((env) => env.id == id);
    if (index != -1) {
      _environments[index] = _environments[index].copyWith(status: status);

      // Update current environment if it matches
      if (_currentEnvironment?.id == id) {
        _currentEnvironment = _currentEnvironment!.copyWith(status: status);
      }

      notifyListeners();
    }
  }

  Future<MetricsResponse> getEnvironmentMetrics(String id) async {
    try {
      return await _apiManager.getEnvironmentMetrics(id);
    } catch (e) {
      ErrorHandler.logError('Failed to get environment metrics', error: e);
      rethrow;
    }
  }

  Future<LogsResponse> getEnvironmentLogs(
    String id, {
    int? lines,
    String? since,
  }) async {
    try {
      return await _apiManager.getEnvironmentLogs(
        id,
        lines: lines,
        since: since,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to get environment logs', error: e);
      rethrow;
    }
  }

  void setCurrentEnvironment(Environment? environment) {
    _currentEnvironment = environment;
    notifyListeners();
  }

  Environment? getEnvironmentById(String id) {
    try {
      return _environments.firstWhere((env) => env.id == id);
    } catch (e) {
      return null;
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

  void _setCreating(bool value) {
    if (_isCreating != value) {
      _isCreating = value;
      notifyListeners();
    }
  }

  void _setError(String? value) {
    if (_error != value) {
      _error = value;
      notifyListeners();
    }
  }
}
