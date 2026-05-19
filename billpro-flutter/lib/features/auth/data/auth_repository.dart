import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  AuthRepository({
    required DioClient dioClient,
    required SharedPreferences prefs,
  })  : _dioClient = dioClient,
        _prefs = prefs;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<String> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'mobile': mobile,
          'password': password,
          'confirmPassword': confirmPassword,
          'acceptTerms': true,
        },
      );
      return response.data['message'] ?? 'Registration successful';
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    try {
      String url = ApiEndpoints.verifyOtp;
      if (purpose == 'password_reset') {
        url += '?type=1';
      }

      final response = await _dioClient.dio.post(
        url,
        data: {
          'identifier': identifier,
          'otp': otp,
          'purpose': purpose,
        },
      );

      return {
        'message': response.data['message'] ?? 'Verification successful',
        'token': response.data['data']?['refreshToken'] ??
            response.data['data']?['token'],
      };
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Login (Email + Password) ──────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data;
      // The backend may nest under 'data' or return at top level
      final data = responseData['data'] ?? responseData;

      // Save tokens (safely handle null)
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      if (accessToken != null && accessToken.isNotEmpty) {
        await _prefs.setString(AppConstants.accessTokenKey, accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      }

      // Parse user — might be nested under 'user' or directly in data
      final userData = data['user'] ?? data;
      final user = UserModel.fromJson(userData as Map<String, dynamic>);

      // Save company ID if available
      if (user.activeCompanyId != null && user.activeCompanyId!.isNotEmpty) {
        await _prefs.setString(
            AppConstants.activeCompanyIdKey, user.activeCompanyId!);
      }

      // Cache user data
      await _prefs.setString(AppConstants.userKey, user.toJsonString());

      return user;
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e, stack) {
      debugPrint('Login parse error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  // ── Get Current User ──────────────────────────────────────────────────────
  Future<UserModel> getMe() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.me);
      final user = UserModel.fromJson(response.data['data']);

      await _prefs.setString(AppConstants.userKey, user.toJsonString());
      return user;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore errors — we clear local state anyway
    } finally {
      await _prefs.remove(AppConstants.accessTokenKey);
      await _prefs.remove(AppConstants.refreshTokenKey);
      await _prefs.remove(AppConstants.activeCompanyIdKey);
      await _prefs.remove(AppConstants.userKey);
    }
  }

  // ── Check if token is expired (decode JWT payload) ────────────────────────
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64 decode the payload (middle part)
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      final exp = payloadMap['exp'];
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Consider expired 60 seconds before actual expiry (buffer)
      return DateTime.now().isAfter(expDate.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return true;
    }
  }

  // ── Try Auto Login — checks token locally first ───────────────────────────
  Future<UserModel?> tryAutoLogin() async {
    final accessToken = _prefs.getString(AppConstants.accessTokenKey);
    final cachedUserJson = _prefs.getString(AppConstants.userKey);

    if (accessToken == null) return null;

    // 1) If access token is NOT expired → load cached user instantly
    if (!_isTokenExpired(accessToken) && cachedUserJson != null) {
      try {
        return UserModel.fromJsonString(cachedUserJson);
      } catch (_) {
        // Cached data corrupted, fall through to API
      }
    }

    // 2) Access token expired — try refresh
    final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);
    if (refreshToken != null) {
      try {
        final refreshDio = Dio(BaseOptions(baseUrl: _dioClient.dio.options.baseUrl));
        final response = await refreshDio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newAccess = response.data['data']['accessToken'];
          final newRefresh = response.data['data']['refreshToken'];

          await _prefs.setString(AppConstants.accessTokenKey, newAccess);
          if (newRefresh != null) {
            await _prefs.setString(AppConstants.refreshTokenKey, newRefresh);
          }

          // Now fetch fresh user data with new token
          return await getMe();
        }
      } catch (_) {
        // Refresh failed
      }
    }

    // 3) Everything failed — clear and return null
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
    return null;
  }

  // ── Forgot Password ────────────────────────────────────────────────────
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return response.data['message'] ??
          'Password reset instructions sent to your email';
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Reset Password (with token from email link) ───────────────────────
  Future<String> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['message'] ?? 'Password reset successful';
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
