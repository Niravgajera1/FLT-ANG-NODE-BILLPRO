import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/dio_client.dart';
import 'models/dashboard_model.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<DashboardSummary> getSummary({
    int fyStartMonth = 4,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/dashboard/summary',
        queryParameters: {
          'fyStartMonth': fyStartMonth,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        return DashboardSummary.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load dashboard');
    } on DioException catch (e) {
      debugPrint('Dashboard getSummary error: ${e.response?.data}');
      throw handleDioError(e);
    }
  }
}
