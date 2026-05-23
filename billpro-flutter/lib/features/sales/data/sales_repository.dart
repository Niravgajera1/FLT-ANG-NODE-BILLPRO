import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/sales_model.dart';

class SalesRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  SalesRepository(
      {required DioClient dioClient, required SharedPreferences prefs})
      : _dioClient = dioClient,
        _prefs = prefs;

  String get _companyId =>
      _prefs.getString(AppConstants.activeCompanyIdKey) ?? '';

  Future<List<OptionModel>> getCustomerOptions() async {
    try {
      final response = await _dioClient.dio.get(
        '/common/options/$_companyId',
        queryParameters: {'type': 2, 'forType': 0},
      );
      final data = response.data['data'];
      if (data is List) return data.map((e) => OptionModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) {
      debugPrint('getCustomerOptions error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<List<OptionModel>> getItemOptions() async {
    try {
      final response = await _dioClient.dio.get(
        '/common/options/$_companyId',
        queryParameters: {'type': 1, 'forType': 1},
      );
      final data = response.data['data'];
      if (data is List) return data.map((e) => OptionModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) {
      debugPrint('getItemOptions error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<List<SalesInvoiceModel>> getInvoices({
    String search = '',
    String invoiceType = '',
    String status = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/sales',
        queryParameters: {
          'companyId': _companyId,
          'page': page,
          'limit': limit,
          if (search.isNotEmpty) 'search': search,
          if (invoiceType.isNotEmpty) 'invoiceType': invoiceType,
          if (status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => SalesInvoiceModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getInvoices error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<SalesInvoiceModel> createInvoice(Map<String, dynamic> payload) async {
    try {
      payload['companyId'] = _companyId;
      final response = await _dioClient.dio.post('/sales', data: payload);
      return SalesInvoiceModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createInvoice error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<SalesInvoiceModel> updateInvoice(String id, Map<String, dynamic> payload) async {
    try {
      payload['companyId'] = _companyId;
      final response = await _dioClient.dio.put('/sales/$id?companyId=$_companyId', data: payload);
      return SalesInvoiceModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('updateInvoice error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _dioClient.dio.delete('/sales/$id');
    } on DioException catch (e) {
      debugPrint('deleteInvoice error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<File> downloadPdf(String id) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/invoice_$id.pdf';

      await _dioClient.dio.download(
        '/sales/$id/pdf',
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
