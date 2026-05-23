import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/purchase_model.dart';
import '../providers/purchase_provider.dart';

class AddEditPurchasePage extends StatefulWidget {
  final PurchaseBillModel? bill;
  const AddEditPurchasePage({super.key, this.bill});

  @override
  State<AddEditPurchasePage> createState() => _AddEditPurchasePageState();
}

class _AddEditPurchasePageState extends State<AddEditPurchasePage> {
  final _formKey = GlobalKey<FormState>();

  // Bill Details
  String? _vendorId;
  final _vendorBillNumber = TextEditingController();
  final _poReference = TextEditingController();
  DateTime? _vendorBillDate;
  DateTime _billDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String? _paymentTerms;
  final _placeOfSupply = TextEditingController();
  bool _isRCM = false;
  final _narration = TextEditingController();
  final _tags = TextEditingController();
  final _paidAmount = TextEditingController(text: '0');

  // Line Items
  final List<Map<String, dynamic>> _lineItems = [];

  // Notes & Terms
  final _notes = TextEditingController();
  final _terms = TextEditingController();

  bool get _isEdit => widget.bill != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _initForEdit(widget.bill!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadOptions();
    });
  }

  void _initForEdit(PurchaseBillModel inv) {
    _vendorId = inv.vendorId;
    _vendorBillNumber.text = inv.vendorBillNumber ?? '';
    _poReference.text = inv.poReference ?? '';
    _vendorBillDate = inv.vendorBillDate != null ? DateTime.tryParse(inv.vendorBillDate!) : null;
    _billDate = DateTime.tryParse(inv.billDate) ?? DateTime.now();
    _dueDate = DateTime.tryParse(inv.dueDate) ?? DateTime.now().add(const Duration(days: 30));
    _placeOfSupply.text = inv.placeOfSupply ?? '';
    _paymentTerms = inv.paymentTerms;
    _isRCM = inv.isRCM;
    _narration.text = inv.narration ?? '';
    _tags.text = inv.tags.join(', ');
    _paidAmount.text = inv.paidAmount.toString();
    _notes.text = inv.notes ?? '';
    _terms.text = inv.termsAndConditions ?? '';

    for (var item in inv.lineItems) {
      _lineItems.add({
        'itemId': item.itemId,
        'itemName': TextEditingController(text: item.itemName),
        'description': TextEditingController(text: item.description ?? ''),
        'hsnCode': TextEditingController(text: item.hsnCode ?? ''),
        'quantity': TextEditingController(text: item.quantity.toString()),
        'unitPrice': TextEditingController(text: item.unitPrice.toString()),
        'unit': item.unit,
        'gstRate': TextEditingController(text: item.gstRate.toString()),
        'cessRate': TextEditingController(text: item.cessRate.toString()),
        'discountPercent': TextEditingController(text: item.discountPercent.toString()),
        'discountFlat': TextEditingController(text: item.discountFlat.toString()),
        'batchNumber': TextEditingController(text: item.batchNumber ?? ''),
      });
    }
  }

  @override
  void dispose() {
    _vendorBillNumber.dispose();
    _poReference.dispose();
    _placeOfSupply.dispose();
    _narration.dispose();
    _tags.dispose();
    _paidAmount.dispose();
    _notes.dispose();
    _terms.dispose();
    for (var item in _lineItems) {
      (item['itemName'] as TextEditingController).dispose();
      (item['description'] as TextEditingController).dispose();
      (item['hsnCode'] as TextEditingController).dispose();
      (item['quantity'] as TextEditingController).dispose();
      (item['unitPrice'] as TextEditingController).dispose();
      (item['gstRate'] as TextEditingController).dispose();
      (item['cessRate'] as TextEditingController).dispose();
      (item['discountPercent'] as TextEditingController).dispose();
      (item['discountFlat'] as TextEditingController).dispose();
      (item['batchNumber'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'itemId': null,
        'itemName': TextEditingController(),
        'description': TextEditingController(),
        'hsnCode': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'unitPrice': TextEditingController(text: '0'),
        'unit': 'pcs',
        'gstRate': TextEditingController(text: '0'),
        'cessRate': TextEditingController(text: '0'),
        'discountPercent': TextEditingController(text: '0'),
        'discountFlat': TextEditingController(text: '0'),
        'batchNumber': TextEditingController(),
      });
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      final item = _lineItems[index];
      (item['itemName'] as TextEditingController).dispose();
      (item['description'] as TextEditingController).dispose();
      (item['hsnCode'] as TextEditingController).dispose();
      (item['quantity'] as TextEditingController).dispose();
      (item['unitPrice'] as TextEditingController).dispose();
      (item['gstRate'] as TextEditingController).dispose();
      (item['cessRate'] as TextEditingController).dispose();
      (item['discountPercent'] as TextEditingController).dispose();
      (item['discountFlat'] as TextEditingController).dispose();
      (item['batchNumber'] as TextEditingController).dispose();
      _lineItems.removeAt(index);
    });
  }

  double _calculateInvoiceTotal() {
    double total = 0;
    for (var item in _lineItems) {
      double qty = double.tryParse((item['quantity'] as TextEditingController).text) ?? 0;
      double price = double.tryParse((item['unitPrice'] as TextEditingController).text) ?? 0;
      double flatDisc = double.tryParse((item['discountFlat'] as TextEditingController).text) ?? 0;
      double pctDisc = double.tryParse((item['discountPercent'] as TextEditingController).text) ?? 0;
      double gstRate = double.tryParse((item['gstRate'] as TextEditingController).text) ?? 0;
      double cessRate = double.tryParse((item['cessRate'] as TextEditingController).text) ?? 0;

      double base = qty * price;
      double disc = flatDisc + (base * (pctDisc / 100));
      double taxable = base - disc;
      if (taxable < 0) taxable = 0;
      double tax = taxable * (gstRate / 100);
      double cess = taxable * (cessRate / 100);
      total += (taxable + tax + cess);
    }
    return total;
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    DateTime init = DateTime.now();
    if (field == 'vendorBillDate' && _vendorBillDate != null) init = _vendorBillDate!;
    if (field == 'billDate') init = _billDate;
    if (field == 'dueDate') init = _dueDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (field == 'vendorBillDate') _vendorBillDate = picked;
        if (field == 'billDate') _billDate = picked;
        if (field == 'dueDate') _dueDate = picked;
      });
    }
  }

  Map<String, dynamic> _buildPayload() {
    final items = _lineItems.map((i) {
      final desc = (i['description'] as TextEditingController).text.trim();
      final hsn = (i['hsnCode'] as TextEditingController).text.trim();
      final batch = (i['batchNumber'] as TextEditingController).text.trim();
      
      return {
        'itemId': i['itemId'],
        'itemName': (i['itemName'] as TextEditingController).text.trim(),
        if (desc.isNotEmpty) 'description': desc,
        if (hsn.isNotEmpty) 'hsnCode': hsn,
        'quantity': double.tryParse((i['quantity'] as TextEditingController).text) ?? 0,
        'unitPrice': double.tryParse((i['unitPrice'] as TextEditingController).text) ?? 0,
        'unit': i['unit'],
        'gstRate': double.tryParse((i['gstRate'] as TextEditingController).text) ?? 0,
        'cessRate': double.tryParse((i['cessRate'] as TextEditingController).text) ?? 0,
        'discountPercent': double.tryParse((i['discountPercent'] as TextEditingController).text) ?? 0,
        'discountFlat': double.tryParse((i['discountFlat'] as TextEditingController).text) ?? 0,
        if (batch.isNotEmpty) 'batchNumber': batch,
      };
    }).toList();

    return {
      'vendorId': _vendorId,
      'vendorBillNumber': _vendorBillNumber.text.trim(),
      'poReference': _poReference.text.trim(),
      if (_vendorBillDate != null) 'vendorBillDate': _vendorBillDate!.toIso8601String(),
      'billDate': _billDate.toIso8601String(),
      'dueDate': _dueDate.toIso8601String(),
      'placeOfSupply': _placeOfSupply.text.trim(),
      'isRCM': _isRCM,
      if (_paymentTerms != null && _paymentTerms!.isNotEmpty) 'paymentTerms': _paymentTerms,
      'narration': _narration.text.trim(),
      'tags': _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'paidAmount': double.tryParse(_paidAmount.text) ?? 0,
      'lineItems': items,
      'notes': _notes.text.trim(),
      'termsAndConditions': _terms.text.trim(),
    };
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorId == null) {
      AppToast.show(context, message: 'Please select a vendor', type: ToastType.error);
      return;
    }
    if (_lineItems.isEmpty) {
      AppToast.show(context, message: 'Please add at least one line item', type: ToastType.error);
      return;
    }
    
    // Check line items validity
    for (var i = 0; i < _lineItems.length; i++) {
      if (_lineItems[i]['itemId'] == null) {
        AppToast.show(context, message: 'Please select a product for Item ${i+1}', type: ToastType.error);
        return;
      }
    }

    final p = context.read<PurchaseProvider>();
    final payload = _buildPayload();
    
    bool success;
    if (_isEdit) {
      success = await p.updateBill(widget.bill!.id, payload);
    } else {
      success = await p.createBill(payload);
    }

    if (mounted && success) {
      Navigator.pop(context, true);
    } else if (mounted) {
      AppToast.show(context, message: p.errorMessage ?? 'Failed', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PurchaseProvider>();
    final vDateFmt = _vendorBillDate == null ? 'Select Date' : "${_vendorBillDate!.day.toString().padLeft(2, '0')}-${_vendorBillDate!.month.toString().padLeft(2, '0')}-${_vendorBillDate!.year}";
    final dFormat = "${_billDate.day.toString().padLeft(2, '0')}-${_billDate.month.toString().padLeft(2, '0')}-${_billDate.year}";
    final dueFormat = "${_dueDate.day.toString().padLeft(2, '0')}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.year}";

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Purchase Bill' : 'Add Purchase Bill', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: p.isSaving ? null : _onSave,
              child: p.isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(_isEdit ? 'Update Bill' : 'Save Bill', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
            // ── BILL DETAILS ──
            _sectionCard('BILL DETAILS', [
              _vendorDropdown(p),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _vendorBillNumber, label: 'Vendor Bill Number')),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _poReference, label: 'PO Reference')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dateField('Vendor Bill Date', vDateFmt, () => _selectDate(context, 'vendorBillDate'))),
                const SizedBox(width: 14),
                Expanded(child: _dateField('Bill Date', dFormat, () => _selectDate(context, 'billDate'))),
                const SizedBox(width: 14),
                Expanded(child: _dateField('Due Date', dueFormat, () => _selectDate(context, 'dueDate'))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _nullableDrop('Payment Terms', _paymentTerms, AppConstants.paymentTerms, 'Select...', 
                  (v) => setState(() => _paymentTerms = v))),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _placeOfSupply, label: 'Place of Supply')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Checkbox(
                  value: _isRCM,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isRCM = v ?? false),
                ),
                const Text('Reverse Charge (RCM)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(flex: 2, child: AppTextField(controller: _narration, label: 'Narration')),
                const SizedBox(width: 14),
                Expanded(flex: 1, child: AppTextField(controller: _tags, label: 'Tags (comma separated)')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _paidAmount, label: 'Amount Paid Upfront (₹)', keyboardType: TextInputType.number)),
                const SizedBox(width: 14),
                const Spacer(),
              ]),
            ]),

            const SizedBox(height: 14),

            // ── LINE ITEMS ──
            _sectionCard('LINE ITEMS', [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addLineItem,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_lineItems.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No items added', style: TextStyle(color: AppColors.textHint)),
                )),
              ..._lineItems.asMap().entries.map((e) => _lineItemCard(e.key, e.value, p)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('ESTIMATED TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('₹${_calculateInvoiceTotal().toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // ── NOTES AND TERMS ──
            _sectionCard('NOTES AND TERMS', [
              AppTextField(controller: _notes, label: 'Notes', maxLines: 3),
              const SizedBox(height: 14),
              AppTextField(controller: _terms, label: 'Terms and Conditions', maxLines: 3),
            ]),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // ── UI HELPERS ──

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _lineItemCard(int index, Map<String, dynamic> item, PurchaseProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          InkWell(
            onTap: () => _removeLineItem(index),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _itemDropdown(item, p)),
          const SizedBox(width: 14),
          Expanded(child: AppTextField(controller: item['itemName'] as TextEditingController, label: 'Item Name')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(flex: 2, child: AppTextField(controller: item['description'] as TextEditingController, label: 'Description')),
          const SizedBox(width: 14),
          Expanded(flex: 1, child: AppTextField(controller: item['hsnCode'] as TextEditingController, label: 'HSN Code')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: AppTextField(
            controller: item['quantity'] as TextEditingController, 
            label: 'Quantity', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
          const SizedBox(width: 14),
          Expanded(child: _dropField('Unit', item['unit'] as String, AppConstants.units, (v) => setState(() => item['unit'] = v ?? 'pcs'))),
          const SizedBox(width: 14),
          Expanded(child: AppTextField(
            controller: item['unitPrice'] as TextEditingController, 
            label: 'Unit Price', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: AppTextField(
            controller: item['gstRate'] as TextEditingController, 
            label: 'GST Rate (%)', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
          const SizedBox(width: 14),
          Expanded(child: AppTextField(
            controller: item['cessRate'] as TextEditingController, 
            label: 'Cess Rate (%)', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: AppTextField(
            controller: item['discountPercent'] as TextEditingController, 
            label: 'Discount %', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
          const SizedBox(width: 14),
          Expanded(child: AppTextField(
            controller: item['discountFlat'] as TextEditingController, 
            label: 'Flat Discount', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
        ]),
        const SizedBox(height: 14),
        AppTextField(controller: item['batchNumber'] as TextEditingController, label: 'Batch Number'),
      ]),
    );
  }

  Widget _vendorDropdown(PurchaseProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Vendor', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _vendorId,
        isExpanded: true,
        hint: const Text('Select vendor', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        items: p.vendors.map((c) => DropdownMenuItem(value: c.id,
            child: Text(c.name, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) => setState(() => _vendorId = v),
      )),
    ),
  ]);

  Widget _itemDropdown(Map<String, dynamic> item, PurchaseProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Product', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: item['itemId'] as String?,
        isExpanded: true,
        hint: const Text('Select product', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        items: p.items.map((i) => DropdownMenuItem(value: i.id,
            child: Text(i.name, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) {
          setState(() {
            item['itemId'] = v;
            final prod = p.items.firstWhere((i) => i.id == v);
            (item['itemName'] as TextEditingController).text = prod.name;
          });
        },
      )),
    ),
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

  Widget _dateField(String label, String display, VoidCallback onTap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Text(display, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    ),
  ]);
}
