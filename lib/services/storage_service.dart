import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../models/user.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final _logger = Logger();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
        _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      ]);
      _logger.i('Tokens saved successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to save tokens', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      return token;
    } catch (e, stackTrace) {
      _logger.e('Failed to get access token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: AppConstants.refreshTokenKey);
      return token;
    } catch (e, stackTrace) {
      _logger.e('Failed to get refresh token',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: AppConstants.userKey, value: userJson);
      _logger.i('User data saved successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to save user data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Failed to get user data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All storage data cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear storage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      return accessToken != null && refreshToken != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, stackTrace) {
      _logger.e('Failed to save value for key: $key',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<String?> getValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stackTrace) {
      _logger.e('Failed to get value for key: $key',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> deleteValue(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete value for key: $key',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
