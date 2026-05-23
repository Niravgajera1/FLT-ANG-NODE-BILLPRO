import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/purchase_model.dart';

class PurchaseRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  PurchaseRepository(
      {required DioClient dioClient, required SharedPreferences prefs})
      : _dioClient = dioClient,
        _prefs = prefs;

  String get _companyId =>
      _prefs.getString(AppConstants.activeCompanyIdKey) ?? '';

  Future<List<OptionModel>> getVendorOptions() async {
    try {
      final response = await _dioClient.dio.get(
        '/common/options/$_companyId',
        queryParameters: {'type': 3, 'forType': 0}, // Or whatever type backend uses for vendors, based on plan approval.
      );
      final data = response.data['data'];
      if (data is List) return data.map((e) => OptionModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) {
      debugPrint('getVendorOptions error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<List<OptionModel>> getItemOptions() async {
    try {
      final response = await _dioClient.dio.get(
        '/common/options/$_companyId',
        queryParameters: {'type': 1, 'forType': 2},
      );
      final data = response.data['data'];
      if (data is List) return data.map((e) => OptionModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) {
      debugPrint('getItemOptions error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<List<PurchaseBillModel>> getPurchaseBills({
    String search = '',
    String status = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/purchase',
        queryParameters: {
          'companyId': _companyId,
          'page': page,
          'limit': limit,
          if (search.isNotEmpty) 'search': search,
          if (status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => PurchaseBillModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getPurchaseBills error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<PurchaseBillModel> createPurchaseBill(Map<String, dynamic> payload) async {
    try {
      payload['companyId'] = _companyId;
      final response = await _dioClient.dio.post('/purchase', data: payload);
      return PurchaseBillModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createPurchaseBill error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<PurchaseBillModel> updatePurchaseBill(String id, Map<String, dynamic> payload) async {
    try {
      payload['companyId'] = _companyId;
      final response = await _dioClient.dio.put('/purchase/$id?companyId=$_companyId', data: payload);
      return PurchaseBillModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('updatePurchaseBill error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<void> deletePurchaseBill(String id) async {
    try {
      await _dioClient.dio.delete('/purchase/$id');
    } on DioException catch (e) {
      debugPrint('deletePurchaseBill error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<File> downloadPdf(String id) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/purchase_bill_$id.pdf';

      await _dioClient.dio.download(
        '/purchase/$id/pdf',
        savePath,
        queryParameters: {'companyId': _companyId},
      );

      return File(savePath);
    } on DioException catch (e) {
      debugPrint('downloadPdf error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }
}
