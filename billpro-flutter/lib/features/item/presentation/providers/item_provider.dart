import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../data/item_repository.dart';
import '../../data/models/item_category_model.dart';
import '../../data/models/item_model.dart';

enum ItemFilter { all, product, service }

class ItemProvider extends ChangeNotifier {
  final ItemRepository _repository;
  ItemProvider({required ItemRepository repository}) : _repository = repository;

  List<ItemModel> _items = [];
  List<ItemModel> _filtered = [];
  List<ItemCategoryModel> _categories = [];
  List<ItemCategoryModel> _categoryOptions = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  ItemFilter _filter = ItemFilter.all;

  List<ItemModel> get items => _filtered;
  List<ItemCategoryModel> get categories => _categories;
  List<ItemCategoryModel> get categoryOptions => _categoryOptions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalCount => _items.length;
  int get lowStockCount => _items.where((i) => i.isLowStock).length;
  int get inactiveCount => _items.where((i) => !i.isActive).length;

  void clearError() { _errorMessage = null; notifyListeners(); }

  void setFilter(ItemFilter f) { _filter = f; _applyFilter(); notifyListeners(); }

  Future<void> loadItems({String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.getItems(itemType: type ?? '');
      _applyFilter();
    } on ServerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load items';
      debugPrint('loadItems: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void search(String q) {
    _searchQuery = q.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    List<ItemModel> base;
    switch (_filter) {
      case ItemFilter.product: base = _items.where((i) => i.itemType == 'product').toList(); break;
      case ItemFilter.service: base = _items.where((i) => i.itemType == 'service').toList(); break;
      case ItemFilter.all: base = List.from(_items); break;
    }
    if (_searchQuery.isEmpty) {
      _filtered = base;
    } else {
      _filtered = base.where((i) =>
        i.name.toLowerCase().contains(_searchQuery) ||
        (i.itemCode?.toLowerCase().contains(_searchQuery) ?? false) ||
        (i.category?.toLowerCase().contains(_searchQuery) ?? false) ||
        (i.brand?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }
  }

  Future<ItemModel?> createItem(Map<String, dynamic> data, {File? image}) async {
    _isSaving = true; _errorMessage = null; notifyListeners();
    try {
      final created = await _repository.createItem(data, image: image);
      _items.insert(0, created);
      _applyFilter();
      _isSaving = false; notifyListeners();
      return created;
    } on ServerException catch (e) {
      _errorMessage = e.message; _isSaving = false; notifyListeners(); return null;
    } catch (e) {
      _errorMessage = 'Failed to create item: $e'; _isSaving = false; notifyListeners(); return null;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data, {File? image}) async {
    _isSaving = true; _errorMessage = null; notifyListeners();
    try {
      final updated = await _repository.updateItem(id, data, image: image);
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) _items[idx] = updated;
      _applyFilter();
      _isSaving = false; notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message; _isSaving = false; notifyListeners(); return false;
    } catch (e) {
      _errorMessage = 'Failed to update item: $e'; _isSaving = false; notifyListeners(); return false;
    }
  }

  Future<void> toggleActive(ItemModel item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx == -1) return;
    final newActive = !item.isActive;
    _items[idx] = item.copyWith(isActive: newActive);
    _applyFilter(); notifyListeners();
    try {
      await _repository.updateItem(item.id, {'isActive': newActive});
    } catch (_) {
      _items[idx] = item;
      _errorMessage = 'Failed to update status';
      _applyFilter(); notifyListeners();
    }
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  Future<void> loadCategoryOptions() async {
    try {
      _categoryOptions = await _repository.getCategoryOptions();
      notifyListeners();
    } catch (e) {
      debugPrint('loadCategoryOptions error: $e');
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('loadCategories error: $e');
    }
  }

  Future<bool> addCategory(String name, String? desc) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newCat = await _repository.addCategory({'name': name, 'description': desc});
      _categories.insert(0, newCat);
      loadCategoryOptions(); // Sync options
      _isSaving = false;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to add category';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(String id, String name, String? desc) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedCat = await _repository.updateCategory(id, {'name': name, 'description': desc});
      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _categories[idx] = updatedCat;
      }
      loadCategoryOptions(); // Sync options
      _isSaving = false;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update category';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      loadCategoryOptions(); // Sync options
      _isSaving = false;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete category';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
