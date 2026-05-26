import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/item_model.dart';
import '../providers/item_provider.dart';
import 'category_management_page.dart';

class AddEditItemPage extends StatefulWidget {
  final ItemModel? item;
  const AddEditItemPage({super.key, this.item});

  @override
  State<AddEditItemPage> createState() => _AddEditItemPageState();
}

class _AddEditItemPageState extends State<AddEditItemPage> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.item != null;
  bool _isLoadingDetails = false;

  // Item Info
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _itemType;
  String? _categoryName;
  late final TextEditingController _brand;
  late String _unit;

  // Pricing & GST
  late final TextEditingController _sellingPrice;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _mrp;
  late final TextEditingController _hsnCode;
  late final TextEditingController _sacCode;
  late final TextEditingController _gstRate;
  late final TextEditingController _cessRate;
  late String? _itcEligibility;
  late bool _priceInclGST;
  late bool _isExempt;

  // Inventory
  late final TextEditingController _openingStock;
  late final TextEditingController _currentStock;
  late final TextEditingController _reorderLevel;
  late final TextEditingController _reorderQty;
  late final TextEditingController _warehouseLocation;
  late final TextEditingController _avgCost;
  late String _valuationMethod;
  late bool _trackInventory;
  late bool _batchTracking;
  late bool _isActive;
  late bool _isSelling;

  // Notes
  late final TextEditingController _notes;

  // Image
  File? _pickedImage;
  final _picker = ImagePicker();

  static const _itemTypes = ['product', 'service'];
  static const _valuationMethods = ['WAC', 'FIFO', 'LIFO'];
  static const _itcOptions = ['full', 'partial', 'none', 'ineligible'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty/default values first
    _name = TextEditingController();
    _description = TextEditingController();
    _itemType = 'product';
    _brand = TextEditingController();
    _unit = 'pcs';
    _sellingPrice = TextEditingController(text: '0');
    _purchasePrice = TextEditingController(text: '0');
    _mrp = TextEditingController(text: '0');
    _hsnCode = TextEditingController();
    _sacCode = TextEditingController();
    _gstRate = TextEditingController(text: '0');
    _cessRate = TextEditingController(text: '0');
    _itcEligibility = null;
    _priceInclGST = false;
    _isExempt = false;
    _openingStock = TextEditingController(text: '0');
    _currentStock = TextEditingController(text: '0');
    _reorderLevel = TextEditingController(text: '0');
    _reorderQty = TextEditingController(text: '0');
    _warehouseLocation = TextEditingController();
    _avgCost = TextEditingController(text: '0');
    _valuationMethod = 'WAC';
    _trackInventory = false;
    _batchTracking = false;
    _isActive = true;
    _isSelling = true;
    _notes = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadCategoryOptions();
      if (_isEdit) {
        _fetchItemDetails();
      }
    });
  }

  /// Fetch full item details from API and populate the form
  Future<void> _fetchItemDetails() async {
    setState(() => _isLoadingDetails = true);
    final provider = context.read<ItemProvider>();
    final fullItem = await provider.loadItemById(widget.item!.id);
    if (fullItem != null && mounted) {
      _populateForm(fullItem);
    } else if (mounted) {
      // Fallback: use the partial data from list if API fails
      _populateForm(widget.item!);
    }
    if (mounted) setState(() => _isLoadingDetails = false);
  }

  /// Populate all form fields from an ItemModel
  void _populateForm(ItemModel c) {
    _name.text = c.name;
    _description.text = c.description ?? '';
    _itemType = c.itemType;
    _categoryName = c.category;
    _brand.text = c.brand ?? '';
    _unit = AppConstants.units.contains(c.unit) ? c.unit : 'pcs';
    _sellingPrice.text = c.sellingPrice.toStringAsFixed(0);
    _purchasePrice.text = c.purchasePrice.toStringAsFixed(0);
    _mrp.text = c.mrp.toStringAsFixed(0);
    _hsnCode.text = c.hsnCode ?? '';
    _sacCode.text = c.sacCode ?? '';
    _gstRate.text = c.gstRate.toStringAsFixed(0);
    _cessRate.text = c.cessRate.toStringAsFixed(0);
    _itcEligibility = _itcOptions.contains(c.itcEligibility) ? c.itcEligibility : null;
    _priceInclGST = c.priceInclGST;
    _isExempt = c.isExempt;
    _openingStock.text = c.openingStock.toStringAsFixed(0);
    _currentStock.text = c.currentStock.toStringAsFixed(0);
    _reorderLevel.text = c.reorderLevel.toStringAsFixed(0);
    _reorderQty.text = c.reorderQuantity.toStringAsFixed(0);
    _warehouseLocation.text = c.warehouseLocation ?? '';
    _avgCost.text = c.avgCost.toStringAsFixed(0);
    _valuationMethod = _valuationMethods.contains(c.valuationMethod) ? c.valuationMethod : 'WAC';
    _trackInventory = c.trackInventory;
    _batchTracking = c.batchTracking;
    _isActive = c.isActive;
    _isSelling = c.isSelling;
    _notes.text = c.notes ?? '';
    setState(() {});
  }


  @override
  void dispose() {
    for (final c in [_name, _description, _brand, _sellingPrice,
      _purchasePrice, _mrp, _hsnCode, _sacCode, _gstRate, _cessRate,
      _openingStock, _currentStock, _reorderLevel, _reorderQty,
      _warehouseLocation, _avgCost, _notes]) { c.dispose(); }
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() => {
    'name': _name.text.trim(),
    'description': _description.text.trim(),
    'itemType': _itemType,
    if (_categoryName != null) 'category': _categoryName,
    'brand': _brand.text.trim(),
    'unit': _unit,
    'sellingPrice': double.tryParse(_sellingPrice.text) ?? 0,
    'purchasePrice': double.tryParse(_purchasePrice.text) ?? 0,
    'mrp': double.tryParse(_mrp.text) ?? 0,
    'hsnCode': _hsnCode.text.trim(),
    'sacCode': _sacCode.text.trim(),
    'gstRate': double.tryParse(_gstRate.text) ?? 0,
    'cessRate': double.tryParse(_cessRate.text) ?? 0,
    if (_itcEligibility != null) 'itcEligibility': _itcEligibility,
    'priceInclGST': _priceInclGST,
    'isExempt': _isExempt,
    'trackInventory': _trackInventory,
    'openingStock': double.tryParse(_openingStock.text) ?? 0,
    'currentStock': double.tryParse(_currentStock.text) ?? 0,
    'reorderLevel': double.tryParse(_reorderLevel.text) ?? 0,
    'reorderQuantity': double.tryParse(_reorderQty.text) ?? 0,
    'warehouseLocation': _warehouseLocation.text.trim(),
    'avgCost': double.tryParse(_avgCost.text) ?? 0,
    'valuationMethod': _valuationMethod,
    'batchTracking': _batchTracking,
    'isActive': _isActive,
    'is_selling': _isSelling,
    'notes': _notes.text.trim(),
  };

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) setState(() => _pickedImage = File(xFile.path));
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = _buildPayload();
    final provider = context.read<ItemProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateItem(widget.item!.id, payload, image: _pickedImage);
    } else {
      success = await provider.createItem(payload, image: _pickedImage) != null;
    }
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      AppToast.show(context, message: provider.errorMessage ?? 'Failed', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Item' : 'Add Item',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (provider.isSaving || _isLoadingDetails) ? null : _onSave,
              child: provider.isSaving
                  ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(_isEdit ? 'Update Item' : 'Save Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
      body: _isLoadingDetails
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading item details...', style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── ITEM INFORMATION ─────────────────────────
            _sectionCard('ITEM INFORMATION', [
              Row(children: [
                Expanded(child: AppTextField(controller: _name, label: 'Name *',
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                const SizedBox(width: 14),
                Expanded(child: _dropField('Item Type', _itemType, _itemTypes,
                    (v) => setState(() => _itemType = v ?? 'product'))),
              ]),
              const SizedBox(height: 14),
              AppTextField(controller: _description, label: 'Description', maxLines: 2),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: _categoryDropdown(provider)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                    tooltip: 'Manage Categories',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<ItemProvider>(),
                            child: const CategoryManagementPage(),
                          ),
                        ),
                      );
                      if (mounted) {
                        context.read<ItemProvider>().loadCategoryOptions();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ]),
              AppTextField(controller: _brand, label: 'Brand'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dropField('Unit', _unit, AppConstants.units,
                    (v) => setState(() => _unit = v ?? 'pcs'))),
                const SizedBox(width: 14),
                Expanded(child: _imagePicker()),
              ]),
            ]),

            const SizedBox(height: 14),

            // ── PRICING & GST ─────────────────────────────
            _sectionCard('PRICING & GST', [
              Row(children: [
                Expanded(child: AppTextField(controller: _sellingPrice, label: 'Selling Price', keyboardType: TextInputType.number)),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _purchasePrice, label: 'Purchase Price', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _mrp, label: 'MRP', keyboardType: TextInputType.number)),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _gstRate, label: 'GST Rate (%)', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _hsnCode, label: 'HSN Code')),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _sacCode, label: 'SAC Code')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _cessRate, label: 'CESS Rate (%)', keyboardType: TextInputType.number)),
                const SizedBox(width: 14),
                Expanded(child: _nullableDrop('ITC Eligibility', _itcEligibility, _itcOptions,
                    'Select...', (v) => setState(() => _itcEligibility = v))),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                _check('Price Includes GST', _priceInclGST, (v) => setState(() => _priceInclGST = v ?? false)),
                _check('GST Exempt', _isExempt, (v) => setState(() => _isExempt = v ?? false)),
              ]),
            ]),

            const SizedBox(height: 14),

            // ── INVENTORY ─────────────────────────────────
            _sectionCard('INVENTORY', [
              Wrap(spacing: 8, children: [
                _check('Track Inventory', _trackInventory, (v) => setState(() => _trackInventory = v ?? false)),
                _check('Batch Tracking', _batchTracking, (v) => setState(() => _batchTracking = v ?? false)),
                _check('Selling Product', _isSelling, (v) => setState(() => _isSelling = v ?? false)),
                _check('Active', _isActive, (v) => setState(() => _isActive = v ?? false)),
              ]),
              if (_trackInventory) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(controller: _openingStock, label: 'Opening Stock', keyboardType: TextInputType.number)),
                  const SizedBox(width: 14),
                  Expanded(child: AppTextField(controller: _currentStock, label: 'Current Stock', keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: AppTextField(controller: _reorderLevel, label: 'Reorder Level', keyboardType: TextInputType.number)),
                  const SizedBox(width: 14),
                  Expanded(child: AppTextField(controller: _reorderQty, label: 'Reorder Qty', keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _dropField('Valuation Method', _valuationMethod, _valuationMethods,
                      (v) => setState(() => _valuationMethod = v ?? 'WAC'))),
                  const SizedBox(width: 14),
                  Expanded(child: AppTextField(controller: _avgCost, label: 'Average Cost', keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 14),
                AppTextField(controller: _warehouseLocation, label: 'Warehouse Location',
                    hint: 'Aisle 4, Shelf B'),
              ],
            ]),

            const SizedBox(height: 14),

            // ── NOTES ─────────────────────────────────────
            _sectionCard('NOTES', [
              AppTextField(controller: _notes, label: 'Notes', maxLines: 3),
            ]),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 1.2)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _check(String label, bool value, void Function(bool?) onChange) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(value: value, onChanged: onChange, activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]);

  Widget _dropField(String label, String value, List<String> items, void Function(String?) onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            items: items.map((v) => DropdownMenuItem(value: v,
                child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChange,
          )),
        ),
      ]);

  Widget _nullableDrop(String label, String? value, List<String> items,
      String hint, void Function(String?) onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
            items: items.map((v) => DropdownMenuItem(value: v,
                child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChange,
          )),
        ),
      ]);

  Widget _categoryDropdown(ItemProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Category', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: (_categoryName != null && p.categoryOptions.any((c) => c.name == _categoryName)) ? _categoryName : null,
        isExpanded: true,
        hint: const Text('Select category', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        items: p.categoryOptions.map((c) => DropdownMenuItem(value: c.name,
            child: Text(c.name, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) => setState(() => _categoryName = v),
      )),
    ),
  ]);

  Widget _imagePicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Image', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: _pickedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.file(_pickedImage!, fit: BoxFit.cover, width: double.infinity))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(widget.item?.image != null ? 'Change Image' : 'Choose Image',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ),
  ]);
}
