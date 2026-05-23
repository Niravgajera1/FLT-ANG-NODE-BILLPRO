import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/vendor_repository.dart';
import '../../data/models/vendor_model.dart';

enum VendorFilter { all, active, inactive }

class VendorProvider extends ChangeNotifier {
  final VendorRepository _repository;

  VendorProvider({required VendorRepository repository})
      : _repository = repository;

  List<VendorModel> _vendors = [];
  List<VendorModel> _filtered = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  VendorFilter _filter = VendorFilter.all;

  List<VendorModel> get vendors => _filtered;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalCount => _vendors.length;
  int get activeCount => _vendors.where((v) => v.isActive).length;
  int get inactiveCount => _vendors.where((v) => !v.isActive).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setFilter(VendorFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  Future<void> loadVendors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vendors = await _repository.getVendors();
      _applyFilter();
    } on ServerException catch (e) {
      _errorMessage = e.message;
      debugPrint('loadVendors error: ${e.message}');
    } catch (e) {
      _errorMessage = 'Failed to load vendors';
      debugPrint('loadVendors error: $e');
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
    List<VendorModel> base;
    switch (_filter) {
      case VendorFilter.active:
        base = _vendors.where((v) => v.isActive).toList();
        break;
      case VendorFilter.inactive:
        base = _vendors.where((v) => !v.isActive).toList();
        break;
      case VendorFilter.all:
        base = List.from(_vendors);
        break;
    }
    
    if (_searchQuery.isEmpty) {
      _filtered = base;
    } else {
      _filtered = base.where((v) {
        return v.name.toLowerCase().contains(_searchQuery) ||
            v.displayName.toLowerCase().contains(_searchQuery) ||
            (v.contactPerson?.toLowerCase().contains(_searchQuery) ?? false) ||
            (v.mobile?.contains(_searchQuery) ?? false) ||
            (v.email?.toLowerCase().contains(_searchQuery) ?? false) ||
            (v.vendorCode?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  Future<VendorModel?> createVendor(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createVendor(data);
      _vendors.insert(0, created);
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
      _errorMessage = 'Failed to create vendor: $e';
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVendor(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateVendor(id, data);
      final idx = _vendors.indexWhere((v) => v.id == id);
      if (idx != -1) _vendors[idx] = updated;
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
      _errorMessage = 'Failed to update vendor: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleActive(VendorModel vendor) async {
    final idx = _vendors.indexWhere((v) => v.id == vendor.id);
    if (idx == -1) return;

    final newActive = !vendor.isActive;
    _vendors[idx] = vendor.copyWith(isActive: newActive);
    _applyFilter();
    notifyListeners();

    try {
      final updated = await _repository.toggleActive(vendor.id);
      _vendors[idx] = updated; // Use the actual updated model from backend
      _applyFilter();
      notifyListeners();
    } catch (e) {
      // Revert on failure
      _vendors[idx] = vendor;
      _errorMessage = 'Failed to update status';
      _applyFilter();
      notifyListeners();
    }
  }
}
