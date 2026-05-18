import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../core/error/exceptions.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  otpVerified,
  forgotPasswordSent,
  resetPasswordSuccess,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _message;
  String? _errorMessage;
  String? _otpIdentifier;
  String? _otpPurpose;
  String? _resetToken;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  String? get otpIdentifier => _otpIdentifier;
  String? get otpPurpose => _otpPurpose;
  String? get resetToken => _resetToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  // ── Check Auth Status ───────────────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authRepository.tryAutoLogin();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Login ───────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Register ────────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _message = await _authRepository.register(
        fullName: fullName,
        email: email,
        mobile: mobile,
        password: password,
        confirmPassword: confirmPassword,
      );
      _otpIdentifier = email;
      _otpPurpose = 'email_verify';
      _status = AuthStatus.otpSent;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Verify OTP ──────────────────────────────────────────────────────────
  Future<bool> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _authRepository.verifyOtp(
        identifier: identifier,
        otp: otp,
        purpose: purpose,
      );
      _message = response['message'];
      if (purpose == 'password_reset') {
        _resetToken = response['token'];
      }
      _status = AuthStatus.otpVerified;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Invalid OTP. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────────────
  Future<bool> forgotPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _message = await _authRepository.forgotPassword(email: email);
      _status = AuthStatus.forgotPasswordSent;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Reset Password ──────────────────────────────────────────────────────
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _message = await _authRepository.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      _status = AuthStatus.resetPasswordSuccess;
      _setLoading(false);
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }
}
