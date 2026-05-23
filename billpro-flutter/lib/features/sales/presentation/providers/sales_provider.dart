import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/models/sales_model.dart';
import '../../data/sales_repository.dart';

class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository;

  SalesProvider({required SalesRepository repository})
      : _repository = repository;

  List<SalesInvoiceModel> _invoices = [];
  List<SalesInvoiceModel> _filtered = [];
  List<OptionModel> _customers = [];
  List<OptionModel> _items = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<SalesInvoiceModel> get invoices => _filtered;
  List<OptionModel> get customers => _customers;
  List<OptionModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalInvoices => _invoices.length;
  int get dueInvoices => _invoices.where((i) => i.balanceDue > 0).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _invoices = await _repository.getInvoices();
      _applyFilter();
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load invoices';
      debugPrint('loadInvoices: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOptions() async {
    try {
      final futures = await Future.wait([
        _repository.getCustomerOptions(),
        _repository.getItemOptions(),
      ]);
      _customers = futures[0];
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
      _filtered = List.from(_invoices);
    } else {
      _filtered = _invoices
          .where((i) =>
              i.customerName.toLowerCase().contains(_searchQuery) ||
              i.invoiceNumber.toLowerCase().contains(_searchQuery) ||
              (i.customerPONumber?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
  }

  Future<bool> createInvoice(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createInvoice(data);
      _invoices.insert(0, created);
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
      _errorMessage = 'Failed to create invoice: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInvoice(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.updateInvoice(id, data);
      final index = _invoices.indexWhere((i) => i.id == id);
      if (index != -1) {
        _invoices[index] = updated;
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
      _errorMessage = 'Failed to update invoice: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteInvoice(id);
      _invoices.removeWhere((i) => i.id == id);
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
      _errorMessage = 'Failed to delete invoice';
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
