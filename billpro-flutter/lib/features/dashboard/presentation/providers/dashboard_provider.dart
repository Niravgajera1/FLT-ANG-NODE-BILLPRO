import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardProvider({required DashboardRepository repository})
      : _repository = repository;

  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _summary != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Load dashboard summary for the current financial year.
  /// Automatically computes FY start date and uses today as end date.
  Future<void> loadSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Financial year starts in April (month 4)
      final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
      final startDate = '$fyStartYear-04-01';
      final endDate = DateFormat('yyyy-MM-dd').format(now);

      _summary = await _repository.getSummary(
        fyStartMonth: 4,
        startDate: startDate,
        endDate: endDate,
      );
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data';
      debugPrint('DashboardProvider loadSummary: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
