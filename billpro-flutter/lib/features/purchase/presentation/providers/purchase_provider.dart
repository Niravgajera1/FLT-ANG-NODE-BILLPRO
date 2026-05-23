import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/models/purchase_model.dart';
import '../../data/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _repository;

  PurchaseProvider({required PurchaseRepository repository})
      : _repository = repository;

  List<PurchaseBillModel> _bills = [];
  List<PurchaseBillModel> _filtered = [];
  List<OptionModel> _vendors = [];
  List<OptionModel> _items = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<PurchaseBillModel> get bills => _filtered;
  List<OptionModel> get vendors => _vendors;
  List<OptionModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalBills => _bills.length;
  int get dueBills => _bills.where((i) => i.balanceDue > 0).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadBills() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bills = await _repository.getPurchaseBills();
      _applyFilter();
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load purchase bills';
      debugPrint('loadBills error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOptions() async {
    try {
      final futures = await Future.wait([
        _repository.getVendorOptions(),
        _repository.getItemOptions(),
      ]);
      _vendors = futures[0];
      _items = futures[1];
      notifyListeners();
    } catch (e) {
      debugPrint('loadOptions error: $e');
    }
  }

  void search(String q) {
    _searchQuery = q.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_bills);
    } else {
      _filtered = _bills
          .where((i) =>
              i.vendorName.toLowerCase().contains(_searchQuery) ||
              i.billNumber.toLowerCase().contains(_searchQuery) ||
              (i.vendorBillNumber?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
  }

  Future<bool> createBill(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createPurchaseBill(data);
      _bills.insert(0, created);
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
      _errorMessage = 'Failed to create bill: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBill(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.updatePurchaseBill(id, data);
      final index = _bills.indexWhere((i) => i.id == id);
      if (index != -1) {
        _bills[index] = updated;
      }
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
      _errorMessage = 'Failed to update bill: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBill(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deletePurchaseBill(id);
      _bills.removeWhere((i) => i.id == id);
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
      _errorMessage = 'Failed to delete bill';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> downloadPdf(String id) async {
    try {
      final file = await _repository.downloadPdf(id);
      await OpenFile.open(file.path);
    } catch (e) {
      _errorMessage = 'Failed to download PDF';
      notifyListeners();
    }
  }
}
