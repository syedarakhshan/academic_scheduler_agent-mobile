import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import 'token_storage.dart';

/// Mirrors frontend/src/utils/api.js:
///   - baseURL from env, 60s timeout for a cold-started DB
///   - attaches `Authorization: Bearer <token>` to every request
///   - on 401, clears stored auth and lets the app react (logout)
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.requestTimeout,
        receiveTimeout: AppConfig.requestTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await TokenStorage.instance.clear();
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  /// Set by AuthProvider at startup so a 401 anywhere in the app can
  /// trigger a logout + redirect to the login screen (equivalent of the
  /// web app's `window.location.href = '/login'`).
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  /// Extracts a friendly message from a DioException the same way the
  /// web app reads `err.response?.data?.message`.
  static String messageFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Request timed out. The server may be waking up — please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Could not reach the server. Check your connection and the API URL.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
