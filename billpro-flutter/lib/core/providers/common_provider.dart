import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class StateItem {
  final String name;
  final String code;
  const StateItem({required this.name, required this.code});

  factory StateItem.fromJson(Map<String, dynamic> json) => StateItem(
        name: json['name'] ?? '',
        code: json['code'] ?? '',
      );
}

class CommonProvider extends ChangeNotifier {
  final DioClient _dioClient;

  CommonProvider({required DioClient dioClient}) : _dioClient = dioClient;

  List<String> _businessTypes = [];
  List<String> _businessCategories = [];
  List<String> _gstTypes = [];
  List<StateItem> _states = [];
  bool _isLoading = false;
  bool _isLoaded = false;

  List<String> get businessTypes => _businessTypes;
  List<String> get businessCategories => _businessCategories;
  List<String> get gstTypes => _gstTypes;
  List<StateItem> get states => _states;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  /// Fetches all dropdown data in parallel. Safe to call multiple times —
  /// won't re-fetch if already loaded.
  Future<void> loadAll() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res1 = await _dioClient.dio.get(ApiEndpoints.businessTypes).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []}));
      final res2 = await _dioClient.dio.get(ApiEndpoints.businessCategories).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []}));
      final res3 = await _dioClient.dio.get(ApiEndpoints.gstTypes).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []}));
      final res4 = await _dioClient.dio.get(ApiEndpoints.states).catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []}));

      _businessTypes = List<String>.from(res1.data['data'] ?? []);
      _businessCategories = List<String>.from(res2.data['data'] ?? []);
      _gstTypes = List<String>.from(res3.data['data'] ?? []);
      
      final statesData = res4.data['data'];
      _states = (statesData as List<dynamic>?)
              ?.map((s) => StateItem.fromJson(s))
              .toList() ??
          [];

      _isLoaded = true;
    } catch (e) {
      debugPrint('CommonProvider loadAll error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
