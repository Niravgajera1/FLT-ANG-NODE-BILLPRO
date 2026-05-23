import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import 'models/customer_model.dart';

class CustomerRepository {
  final DioClient _dioClient;

  CustomerRepository({required DioClient dioClient}) : _dioClient = dioClient;

  static const String _base = '/customers';

  /// GET /customers  — X-Company-Id header set automatically by interceptor
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final response = await _dioClient.dio.get(_base);
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data.map((c) => CustomerModel.fromJson(c)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getCustomers error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// POST /customers
  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(_base, data: data);
      return CustomerModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createCustomer error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// PUT /customers/:id
  Future<CustomerModel> updateCustomer(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.dio.put('$_base/$id', data: data);
      return CustomerModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('updateCustomer error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// Toggle isActive via PUT /customers/:id
  Future<CustomerModel> toggleActive(
      String id, bool isActive, Map<String, dynamic> fullData) async {
    return updateCustomer(id, {...fullData, 'isActive': isActive});
  }
}
