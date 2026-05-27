import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../config/app_constants.dart';
import '../config/api_endpoints.dart';
import '../error/exceptions.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class DioClient {
  late final Dio dio;
  final SharedPreferences _prefs;

  DioClient({required SharedPreferences prefs}) : _prefs = prefs {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(prefs: _prefs, dio: dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor({required SharedPreferences prefs, required Dio dio})
      : _prefs = prefs,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _prefs.getString(AppConstants.accessTokenKey);
    final companyId = _prefs.getString(AppConstants.activeCompanyIdKey);

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
        final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);
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

          await _prefs.setString(
              AppConstants.accessTokenKey, newAccessToken);
          if (newRefreshToken != null) {
            await _prefs.setString(
                AppConstants.refreshTokenKey, newRefreshToken);
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
        await _prefs.remove(AppConstants.accessTokenKey);
        await _prefs.remove(AppConstants.refreshTokenKey);
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

    // ── Parse field-level validation errors array ──────────────────────────
    // API format: { "errors": [{ "field": "otp", "message": "OTP is required" }] }
    List<Map<String, dynamic>>? errors;
    if (data is Map && data['errors'] is List) {
      errors = List<Map<String, dynamic>>.from(
        (data['errors'] as List).whereType<Map>(),
      );
    }

    // Build a human-readable message from the errors array when present,
    // otherwise fall back to the top-level "message" field.
    String message;
    if (errors != null && errors.isNotEmpty) {
      message = errors
          .map((e) {
            final field = e['field']?.toString();
            final msg = e['message']?.toString() ?? '';
            return field != null && field.isNotEmpty ? '$field: $msg' : msg;
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
      // If no messages were extracted, fall back to top-level message
      if (message.isEmpty) {
        message = data is Map
            ? (data['message']?.toString() ?? 'Validation failed')
            : 'Validation failed';
      }
    } else {
      message = data is Map
          ? (data['message']?.toString() ?? 'Something went wrong')
          : 'Something went wrong';
    }

    return ServerException(
      message: message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }

  return ServerException(
      message: e.message ?? 'Unknown error occurred', statusCode: 0);
}

