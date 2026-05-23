import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/item_model.dart';

class ItemRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  ItemRepository({required DioClient dioClient, required SharedPreferences prefs})
      : _dioClient = dioClient,
        _prefs = prefs;

  String get _companyId => _prefs.getString(AppConstants.activeCompanyIdKey) ?? '';

  /// GET /items?companyId=...&page=1&limit=20&search=&itemType=...
  Future<List<ItemModel>> getItems({
    String search = '',
    String itemType = '',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/items',
        queryParameters: {
          'companyId': _companyId,
          'page': page,
          'limit': limit,
          if (search.isNotEmpty) 'search': search,
          if (itemType.isNotEmpty) 'itemType': itemType,
        },
      );
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) return data.map((e) => ItemModel.fromJson(e)).toList();
      return [];
    } on DioException catch (e) {
      debugPrint('getItems error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// POST /items — multipart form data
  Future<ItemModel> createItem(Map<String, dynamic> fields, {File? image}) async {
    try {
      final formData = await _buildFormData(fields, image: image);
      final response = await _dioClient.dio.post('/items', data: formData);
      return ItemModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('createItem error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  /// PUT /items/:id
  Future<ItemModel> updateItem(String id, Map<String, dynamic> fields, {File? image}) async {
    try {
      final formData = await _buildFormData(fields, image: image);
      final response = await _dioClient.dio.put('/items/$id', data: formData);
      return ItemModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('updateItem error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }

  Future<FormData> _buildFormData(Map<String, dynamic> fields, {File? image}) async {
    final map = <String, dynamic>{
      'companyId': _companyId,
      ...fields.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    };
    if (image != null) {
      map['image'] = await MultipartFile.fromFile(image.path,
          filename: image.path.split('/').last);
    }
    return FormData.fromMap(map);
  }
}
