import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import 'models/company_model.dart';

class ProfileRepository {
  final DioClient _dioClient;

  ProfileRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<CompanyModel?> getCompanyDetails(String companyId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.companies,
        queryParameters: {'companyId': companyId},
      );
      
      final data = response.data['data'];
      if (data == null) return null;
      
      // If the API returns a list (e.g. searching by companyId), take the first or parse the object
      if (data is List) {
        if (data.isEmpty) return null;
        return CompanyModel.fromJson(data.first);
      }
      
      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
