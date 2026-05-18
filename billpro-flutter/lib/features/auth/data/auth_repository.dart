import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required DioClient dioClient,
    required FlutterSecureStorage storage,
  })  : _dioClient = dioClient,
        _storage = storage;

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
        'token': response.data['data']?['refreshToken'] ?? response.data['data']?['token'],
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

      final data = response.data['data'];

      // Save tokens
      await _storage.write(
          key: AppConstants.accessTokenKey, value: data['accessToken']);
      await _storage.write(
          key: AppConstants.refreshTokenKey, value: data['refreshToken']);

      // Parse user
      final user = UserModel.fromJson(data['user']);

      // Save company ID if available
      if (user.activeCompanyId != null) {
        await _storage.write(
            key: AppConstants.activeCompanyIdKey,
            value: user.activeCompanyId);
      }

      // Cache user data
      await _storage.write(
          key: AppConstants.userKey, value: user.toJsonString());

      return user;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Get Current User ──────────────────────────────────────────────────────
  Future<UserModel> getMe() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.me);
      final user = UserModel.fromJson(response.data['data']);

      await _storage.write(
          key: AppConstants.userKey, value: user.toJsonString());
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
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.activeCompanyIdKey);
      await _storage.delete(key: AppConstants.userKey);
    }
  }

  // ── Check if logged in (from stored token) ────────────────────────────────
  Future<UserModel?> tryAutoLogin() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) return null;

    try {
      return await getMe();
    } catch (_) {
      // Token invalid — clear and return null
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      return null;
    }
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
