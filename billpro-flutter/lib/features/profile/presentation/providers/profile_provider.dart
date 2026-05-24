import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/models/company_model.dart';
import '../../data/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider({required ProfileRepository repository})
      : _repository = repository;

  CompanyModel? _company;
  bool _isLoadingCompany = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;
  bool _hasNoCompany = false;

  CompanyModel? get company => _company;
  bool get isLoadingCompany => _isLoadingCompany;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasNoCompany => _hasNoCompany;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// GET /companies — backend resolves company from auth token
  Future<void> loadCompanyDetails() async {
    _isLoadingCompany = true;
    _errorMessage = null;
    _hasNoCompany = false;
    notifyListeners();

    try {
      _company = await _repository.getCompanyDetails();
      if (_company == null) {
        _hasNoCompany = true;
      }
    } on ServerException catch (e) {
      _hasNoCompany = true;
      _errorMessage = null;
      debugPrint('loadCompanyDetails: ${e.message}');
    } catch (e) {
      _hasNoCompany = true;
      debugPrint('loadCompanyDetails error: $e');
    }

    _isLoadingCompany = false;
    notifyListeners();
  }

  /// POST /companies — create new company
  Future<CompanyModel?> createCompany(Map<String, dynamic> data) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _company = await _repository.createCompany(data);
      _hasNoCompany = false;
      _successMessage = 'Company created successfully';
      _isUpdating = false;
      notifyListeners();
      return _company;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create company: $e';
      _isUpdating = false;
      notifyListeners();
      return null;
    }
  }

  /// PUT /companies — update existing company
  Future<bool> updateCompany(String companyId, Map<String, dynamic> data) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _company = await _repository.updateCompany(companyId, data);
      _successMessage = 'Company updated successfully';
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update company';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }
}
