import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/models/company_model.dart';
import '../../data/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileProvider({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  CompanyModel? _company;
  bool _isLoadingCompany = false;
  String? _errorMessage;

  CompanyModel? get company => _company;
  bool get isLoadingCompany => _isLoadingCompany;
  String? get errorMessage => _errorMessage;

  Future<void> loadCompanyDetails(String companyId) async {
    _isLoadingCompany = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _company = await _profileRepository.getCompanyDetails(companyId);
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load business details';
    } finally {
      _isLoadingCompany = false;
      notifyListeners();
    }
  }
}
