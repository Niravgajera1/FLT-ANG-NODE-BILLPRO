import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import 'models/vendor_model.dart';

class VendorRepository {
  final DioClient _dioClient;

  VendorRepository({required DioClient dioClient}) : _dioClient = dioClient;

  static const String _base = '/vendors';

  Future<List<VendorModel>> getVendors() async {
    try {
      final response = await _dioClient.dio.get(_base);
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data.map((v) => VendorModel.fromJson(v)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getVendors error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<VendorModel> createVendor(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(_base, data: data);
      return VendorModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createVendor error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<VendorModel> updateVendor(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put('$_base/$id', data: data);
      return VendorModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('updateVendor error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<VendorModel> toggleActive(String id) async {
    try {
      final response = await _dioClient.dio.delete('$_base/$id');
      return VendorModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('toggleActive vendor error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }
}
