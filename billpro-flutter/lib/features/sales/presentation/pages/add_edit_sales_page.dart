import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/sales_model.dart';
import '../providers/sales_provider.dart';

class AddEditSalesPage extends StatefulWidget {
  final SalesInvoiceModel? invoice;
  const AddEditSalesPage({super.key, this.invoice});

  @override
  State<AddEditSalesPage> createState() => _AddEditSalesPageState();
}

class _AddEditSalesPageState extends State<AddEditSalesPage> {
  final _formKey = GlobalKey<FormState>();

  // Invoice Details
  String? _customerId;
  String _invoiceType = AppConstants.invoiceTax;
  final _poNumber = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _placeOfSupply = TextEditingController();
  final _dispatchFrom = TextEditingController();
  String? _paymentTerms;

  // Addresses
  final Map<String, TextEditingController> _billing = {
    'label': TextEditingController(text: 'Office Address'),
    'line1': TextEditingController(),
    'line2': TextEditingController(),
    'city': TextEditingController(),
    'state': TextEditingController(),
    'stateCode': TextEditingController(),
    'pinCode': TextEditingController(),
    'country': TextEditingController(text: 'India'),
  };
  final Map<String, TextEditingController> _shipping = {
    'label': TextEditingController(text: 'Warehouse Address'),
    'line1': TextEditingController(),
    'line2': TextEditingController(),
    'city': TextEditingController(),
    'state': TextEditingController(),
    'stateCode': TextEditingController(),
    'pinCode': TextEditingController(),
    'country': TextEditingController(text: 'India'),
  };

  // Line Items
  final List<Map<String, dynamic>> _lineItems = [];

  // Notes & Terms
  final _notes = TextEditingController();
  final _terms = TextEditingController();

  final _paidAmount = TextEditingController(text: '0');

  bool get _isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _initForEdit(widget.invoice!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadOptions();
    });
  }

  void _initForEdit(SalesInvoiceModel inv) {
    _customerId = inv.customerId;
    _invoiceType = inv.invoiceType;
    _poNumber.text = inv.customerPONumber ?? '';
    _invoiceDate = DateTime.tryParse(inv.invoiceDate) ?? DateTime.now();
    _dueDate = DateTime.tryParse(inv.dueDate) ?? DateTime.now().add(const Duration(days: 30));
    _placeOfSupply.text = inv.placeOfSupply ?? '';
    _dispatchFrom.text = inv.dispatchFrom ?? '';
    _paymentTerms = inv.paymentTerms;
    _paidAmount.text = inv.paidAmount.toString();
    _notes.text = inv.notes ?? '';
    _terms.text = inv.termsAndConditions ?? '';

    if (inv.billingAddress != null) {
      _billing['label']!.text = inv.billingAddress!.label;
      _billing['line1']!.text = inv.billingAddress!.line1;
      _billing['line2']!.text = inv.billingAddress!.line2 ?? '';
      _billing['city']!.text = inv.billingAddress!.city;
      _billing['state']!.text = inv.billingAddress!.state;
      _billing['stateCode']!.text = inv.billingAddress!.stateCode;
      _billing['pinCode']!.text = inv.billingAddress!.pinCode;
      _billing['country']!.text = inv.billingAddress!.country;
    }

    if (inv.shippingAddress != null) {
      _shipping['label']!.text = inv.shippingAddress!.label;
      _shipping['line1']!.text = inv.shippingAddress!.line1;
      _shipping['line2']!.text = inv.shippingAddress!.line2 ?? '';
      _shipping['city']!.text = inv.shippingAddress!.city;
      _shipping['state']!.text = inv.shippingAddress!.state;
      _shipping['stateCode']!.text = inv.shippingAddress!.stateCode;
      _shipping['pinCode']!.text = inv.shippingAddress!.pinCode;
      _shipping['country']!.text = inv.shippingAddress!.country;
    }

    for (var item in inv.lineItems) {
      _lineItems.add({
        'itemId': item.itemId,
        'itemName': TextEditingController(text: item.itemName),
        'quantity': TextEditingController(text: item.quantity.toString()),
        'unitPrice': TextEditingController(text: item.unitPrice.toString()),
        'unit': item.unit,
        'gstRate': TextEditingController(text: item.gstRate.toString()),
        'discountPercent': TextEditingController(text: item.discountPercent.toString()),
        'discountFlat': TextEditingController(text: item.discountFlat.toString()),
      });
    }
  }

  @override
  void dispose() {
    _poNumber.dispose();
    _placeOfSupply.dispose();
    _dispatchFrom.dispose();
    _paidAmount.dispose();
    _notes.dispose();
    _terms.dispose();
    for (var c in _billing.values) { c.dispose(); }
    for (var c in _shipping.values) { c.dispose(); }
    for (var item in _lineItems) {
      (item['itemName'] as TextEditingController).dispose();
      (item['quantity'] as TextEditingController).dispose();
      (item['unitPrice'] as TextEditingController).dispose();
      (item['gstRate'] as TextEditingController).dispose();
      (item['discountPercent'] as TextEditingController).dispose();
      (item['discountFlat'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'itemId': null,
        'itemName': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'unitPrice': TextEditingController(text: '0'),
        'unit': 'pcs',
        'gstRate': TextEditingController(text: '0'),
        'discountPercent': TextEditingController(text: '0'),
        'discountFlat': TextEditingController(text: '0'),
      });
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      final item = _lineItems[index];
      (item['itemName'] as TextEditingController).dispose();
      (item['quantity'] as TextEditingController).dispose();
      (item['unitPrice'] as TextEditingController).dispose();
      (item['gstRate'] as TextEditingController).dispose();
      (item['discountPercent'] as TextEditingController).dispose();
      (item['discountFlat'] as TextEditingController).dispose();
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

      double base = qty * price;
      double disc = flatDisc + (base * (pctDisc / 100));
      double taxable = base - disc;
      if (taxable < 0) taxable = 0;
      double tax = taxable * (gstRate / 100);
      total += (taxable + tax);
    }
    return total;
  }

  Future<void> _selectDate(BuildContext context, bool isDue) async {
    final init = isDue ? _dueDate : _invoiceDate;
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
        if (isDue) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  Map<String, dynamic> _buildPayload() {
    final billing = {
      'label': _billing['label']!.text.trim(),
      'line1': _billing['line1']!.text.trim(),
      'line2': _billing['line2']!.text.trim(),
      'city': _billing['city']!.text.trim(),
      'state': _billing['state']!.text.trim(),
      'stateCode': _billing['stateCode']!.text.trim(),
      'pinCode': _billing['pinCode']!.text.trim(),
      'country': _billing['country']!.text.trim(),
    };
    final shipping = {
      'label': _shipping['label']!.text.trim(),
      'line1': _shipping['line1']!.text.trim(),
      'line2': _shipping['line2']!.text.trim(),
      'city': _shipping['city']!.text.trim(),
      'state': _shipping['state']!.text.trim(),
      'stateCode': _shipping['stateCode']!.text.trim(),
      'pinCode': _shipping['pinCode']!.text.trim(),
      'country': _shipping['country']!.text.trim(),
    };

    final items = _lineItems.map((i) => {
      'itemId': i['itemId'],
      'itemName': (i['itemName'] as TextEditingController).text.trim(),
      'quantity': double.tryParse((i['quantity'] as TextEditingController).text) ?? 0,
      'unitPrice': double.tryParse((i['unitPrice'] as TextEditingController).text) ?? 0,
      'unit': i['unit'],
      'gstRate': double.tryParse((i['gstRate'] as TextEditingController).text) ?? 0,
      'discountPercent': double.tryParse((i['discountPercent'] as TextEditingController).text) ?? 0,
      'discountFlat': double.tryParse((i['discountFlat'] as TextEditingController).text) ?? 0,
    }).toList();

    return {
      'customerId': _customerId,
      'invoiceType': _invoiceType,
      'customerPONumber': _poNumber.text.trim(),
      'invoiceDate': _invoiceDate.toIso8601String(),
      'dueDate': _dueDate.toIso8601String(),
      'placeOfSupply': _placeOfSupply.text.trim(),
      'dispatchFrom': _dispatchFrom.text.trim(),
      if (_paymentTerms != null && _paymentTerms!.isNotEmpty) 'paymentTerms': _paymentTerms,
      'paidAmount': double.tryParse(_paidAmount.text) ?? 0,
      'billingAddress': billing,
      'shippingAddress': shipping,
      'lineItems': items,
      'notes': _notes.text.trim(),
      'termsAndConditions': _terms.text.trim(),
    };
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      AppToast.show(context, message: 'Please select a customer', type: ToastType.error);
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

    final p = context.read<SalesProvider>();
    final payload = _buildPayload();
    
    bool success;
    if (_isEdit) {
      success = await p.updateInvoice(widget.invoice!.id, payload);
    } else {
      success = await p.createInvoice(payload);
    }

    if (mounted && success) {
      Navigator.pop(context, true);
    } else if (mounted) {
      AppToast.show(context, message: p.errorMessage ?? 'Failed', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SalesProvider>();
    final dFormat = "${_invoiceDate.day.toString().padLeft(2, '0')}-${_invoiceDate.month.toString().padLeft(2, '0')}-${_invoiceDate.year}";
    final dueFormat = "${_dueDate.day.toString().padLeft(2, '0')}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.year}";

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Invoice' : 'Add Invoice', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  : Text(_isEdit ? 'Update Invoice' : 'Save Invoice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
            // ── INVOICE DETAILS ──
            _sectionCard('INVOICE DETAILS', [
              _customerDropdown(p),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dropField('Invoice Type', _invoiceType, 
                    [AppConstants.invoiceTax, AppConstants.invoiceBillOfSupply, AppConstants.invoiceExport], 
                    (v) => setState(() => _invoiceType = v ?? AppConstants.invoiceTax))),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _poNumber, label: 'Customer PO Number')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dateField('Invoice Date', dFormat, () => _selectDate(context, false))),
                const SizedBox(width: 14),
                Expanded(child: _dateField('Due Date', dueFormat, () => _selectDate(context, true))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _placeOfSupply, label: 'Place of Supply')),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _dispatchFrom, label: 'Dispatch From')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _nullableDrop('Payment Terms', _paymentTerms, AppConstants.paymentTerms, 'Select...', 
                  (v) => setState(() => _paymentTerms = v))),
                const SizedBox(width: 14),
                Expanded(child: AppTextField(controller: _paidAmount, label: 'Amount Paid Upfront (₹)', keyboardType: TextInputType.number)),
              ]),
            ]),

            const SizedBox(height: 14),

            // ── ADDRESSES ──
            _sectionCard('ADDRESSES', [
              const Text('Billing Address', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              _addressForm(_billing),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border),
              const SizedBox(height: 14),
              const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              _addressForm(_shipping),
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

  Widget _addressForm(Map<String, TextEditingController> map) => Column(children: [
    Row(children: [
      Expanded(child: AppTextField(controller: map['label']!, label: 'Label')),
      const SizedBox(width: 14),
      Expanded(child: AppTextField(controller: map['country']!, label: 'Country')),
    ]),
    const SizedBox(height: 14),
    AppTextField(controller: map['line1']!, label: 'Line 1'),
    const SizedBox(height: 14),
    AppTextField(controller: map['line2']!, label: 'Line 2'),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: AppTextField(controller: map['city']!, label: 'City')),
      const SizedBox(width: 14),
      Expanded(child: AppTextField(controller: map['state']!, label: 'State')),
    ]),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: AppTextField(controller: map['stateCode']!, label: 'State Code')),
      const SizedBox(width: 14),
      Expanded(child: AppTextField(controller: map['pinCode']!, label: 'PIN Code')),
    ]),
  ]);

  Widget _lineItemCard(int index, Map<String, dynamic> item, SalesProvider p) {
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
          Expanded(child: AppTextField(
            controller: item['quantity'] as TextEditingController, 
            label: 'Quantity', 
            keyboardType: TextInputType.number,
            onChanged: (_) => setState((){})
          )),
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
          Expanded(child: _dropField('Unit', item['unit'] as String, AppConstants.units, (v) => setState(() => item['unit'] = v ?? 'pcs'))),
          const SizedBox(width: 14),
          Expanded(child: AppTextField(
            controller: item['gstRate'] as TextEditingController, 
            label: 'GST Rate (%)', 
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
      ]),
    );
  }

  Widget _customerDropdown(SalesProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Customer', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _customerId,
        isExpanded: true,
        hint: const Text('Select customer', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        items: p.customers.map((c) => DropdownMenuItem(value: c.id,
            child: Text(c.name, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) => setState(() => _customerId = v),
      )),
    ),
  ]);

  Widget _itemDropdown(Map<String, dynamic> item, SalesProvider p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
