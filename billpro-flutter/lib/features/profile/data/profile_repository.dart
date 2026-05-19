import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import 'models/company_model.dart';

class ProfileRepository {
  final DioClient _dioClient;

  ProfileRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// GET /companies?companyId=...
  Future<CompanyModel?> getCompanyDetails(String companyId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.companies,
        queryParameters: {'companyId': companyId},
      );

      final data = response.data['data'];
      if (data == null) return null;

      if (data is List) {
        if (data.isEmpty) return null;
        return CompanyModel.fromJson(data.first);
      }

      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      // 400 = no company context = new user with no company
      if (e.response?.statusCode == 400) return null;
      throw handleDioError(e);
    }
  }

  /// POST /companies — create a new company
  Future<CompanyModel> createCompany(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.companies,
        data: data,
      );
      return CompanyModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createCompany error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// PUT /companies — update existing company
  Future<CompanyModel> updateCompany(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put(
        ApiEndpoints.companies,
        data: data,
      );
      return CompanyModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
