import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../config/app_constants.dart';
import '../config/api_endpoints.dart';
import '../error/exceptions.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class DioClient {
  late final Dio dio;
  final FlutterSecureStorage _storage;

  DioClient({required FlutterSecureStorage storage}) : _storage = storage {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(storage: _storage, dio: dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor({required FlutterSecureStorage storage, required Dio dio})
      : _storage = storage,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final companyId = await _storage.read(key: AppConstants.activeCompanyIdKey);

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (companyId != null) {
      options.headers['X-Company-Id'] = companyId;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.reject(err);
        }

        // Try to refresh the token
        final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
        final response = await refreshDio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newAccessToken = response.data['data']['accessToken'];
          final newRefreshToken = response.data['data']['refreshToken'];

          await _storage.write(
              key: AppConstants.accessTokenKey, value: newAccessToken);
          if (newRefreshToken != null) {
            await _storage.write(
                key: AppConstants.refreshTokenKey, value: newRefreshToken);
          }

          // Retry the original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(opts);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed — clear tokens
        await _storage.delete(key: AppConstants.accessTokenKey);
        await _storage.delete(key: AppConstants.refreshTokenKey);
      }
      _isRefreshing = false;
    }

    handler.reject(err);
  }
}

// ── Helper to parse Dio errors into app exceptions ──────────────────────────
ServerException handleDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const ServerException(
        message: 'Connection timed out. Please try again.', statusCode: 408);
  }

  if (e.type == DioExceptionType.connectionError) {
    return const ServerException(
        message: 'Unable to connect to server. Check your internet.',
        statusCode: 0);
  }

  final response = e.response;
  if (response != null) {
    final data = response.data;
    final message = data is Map
        ? (data['message'] ?? 'Something went wrong')
        : 'Something went wrong';
    final errors = data is Map && data['errors'] != null
        ? List<Map<String, dynamic>>.from(data['errors'])
        : null;

    return ServerException(
      message: message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }

  return ServerException(
      message: e.message ?? 'Unknown error occurred', statusCode: 0);
}
