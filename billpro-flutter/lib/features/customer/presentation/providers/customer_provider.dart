import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/customer_repository.dart';
import '../../data/models/customer_model.dart';

enum CustomerFilter { all, active, inactive }

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository;

  CustomerProvider({required CustomerRepository repository})
      : _repository = repository;

  List<CustomerModel> _customers = [];
  List<CustomerModel> _filtered = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  CustomerFilter _filter = CustomerFilter.all;

  List<CustomerModel> get customers => _filtered;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalCount => _customers.length;
  int get activeCount => _customers.where((c) => c.isActive).length;
  int get inactiveCount => _customers.where((c) => !c.isActive).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setFilter(CustomerFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  /// GET /customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers();
      _applyFilter();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      debugPrint('loadCustomers error: ${e.message}');
    } catch (e) {
      _errorMessage = 'Failed to load customers';
      debugPrint('loadCustomers error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    // 1. Apply active/inactive filter
    List<CustomerModel> base;
    switch (_filter) {
      case CustomerFilter.active:
        base = _customers.where((c) => c.isActive).toList();
        break;
      case CustomerFilter.inactive:
        base = _customers.where((c) => !c.isActive).toList();
        break;
      case CustomerFilter.all:
        base = List.from(_customers);
        break;
    }
    // 2. Apply search on top
    if (_searchQuery.isEmpty) {
      _filtered = base;
    } else {
      _filtered = base.where((c) {
        return c.name.toLowerCase().contains(_searchQuery) ||
            c.displayName.toLowerCase().contains(_searchQuery) ||
            (c.contactPerson?.toLowerCase().contains(_searchQuery) ?? false) ||
            (c.mobile?.contains(_searchQuery) ?? false) ||
            (c.email?.toLowerCase().contains(_searchQuery) ?? false) ||
            (c.customerCode?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  /// POST /customers
  Future<CustomerModel?> createCustomer(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createCustomer(data);
      _customers.insert(0, created);
      _applyFilter();
      _isSaving = false;
      notifyListeners();
      return created;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create customer: $e';
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// PUT /customers/:id
  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCustomer(id, data);
      final idx = _customers.indexWhere((c) => c.id == id);
      if (idx != -1) _customers[idx] = updated;
      _applyFilter();
      _isSaving = false;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update customer: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle isActive (no separate delete endpoint)
  Future<void> toggleActive(CustomerModel customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx == -1) return;

    final newActive = !customer.isActive;
    _customers[idx] = customer.copyWith(isActive: newActive);
    _applyFilter();
    notifyListeners();

    try {
      await _repository.toggleActive(customer.id, newActive, customer.toJson());
    } catch (e) {
      // Revert on failure
      _customers[idx] = customer;
      _errorMessage = 'Failed to update status';
      _applyFilter();
      notifyListeners();
    }
  }
}
