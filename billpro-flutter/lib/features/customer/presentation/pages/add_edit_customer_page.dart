import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/common_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';

class AddEditCustomerPage extends StatefulWidget {
  final CustomerModel? customer;
  const AddEditCustomerPage({super.key, this.customer});

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.customer != null;

  // Basic
  late final TextEditingController _name;
  late final TextEditingController _displayName;
  late final TextEditingController _customerGroup;
  late String _customerType;

  // Tax & Contact
  late final TextEditingController _gstin;
  late final TextEditingController _pan;
  late final TextEditingController _contactPerson;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _altMobile;
  late final TextEditingController _website;
  late bool _isGSTRegistered;
  late bool _isActive;

  // Addresses
  late List<_AddressEntry> _addresses;

  // Commercial
  late String? _paymentTerms;
  late final TextEditingController _creditLimit;
  late final TextEditingController _openingBalance;
  late final TextEditingController _discountPercent;
  late final TextEditingController _tags;
  late final TextEditingController _notes;
  DateTime? _openingBalanceDate;

  static const List<String> _paymentTermsOptions = [
    'Due on Receipt',
    'Net 7',
    'Net 15',
    'Net 30',
    'Net 60',
    'Net 90',
  ];


  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name ?? '');
    _displayName = TextEditingController(text: c?.displayName ?? '');
    _customerGroup = TextEditingController(text: c?.customerGroup ?? '');
    _customerType = c?.customerType ?? 'B2B';
    _gstin = TextEditingController(text: c?.gstin ?? '');
    _pan = TextEditingController(text: c?.pan ?? '');
    _contactPerson = TextEditingController(text: c?.contactPerson ?? '');
    _mobile = TextEditingController(text: c?.mobile ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _altMobile = TextEditingController(text: c?.altMobile ?? '');
    _website = TextEditingController(text: c?.website ?? '');
    _isGSTRegistered = c?.isGSTRegistered ?? false;
    _isActive = c?.isActive ?? true;
    _addresses = (c?.addresses.isNotEmpty == true)
        ? c!.addresses.map((a) => _AddressEntry.fromModel(a)).toList()
        : [_AddressEntry()];
    _paymentTerms = (_paymentTermsOptions.contains(c?.paymentTerms))
        ? c?.paymentTerms
        : null;

    _creditLimit = TextEditingController(text: c?.creditLimit.toStringAsFixed(0) ?? '0');
    _openingBalance = TextEditingController(text: c?.openingBalance.toStringAsFixed(0) ?? '0');
    _discountPercent = TextEditingController(text: c?.discountPercent.toStringAsFixed(1) ?? '0.0');
    _tags = TextEditingController(text: c?.tags.join(', ') ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    if (c?.openingBalanceDate != null) {
      _openingBalanceDate = DateTime.tryParse(c!.openingBalanceDate!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommonProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _displayName, _customerGroup, _gstin, _pan,
      _contactPerson, _mobile, _email, _altMobile, _website,
      _creditLimit, _openingBalance, _discountPercent,
      _tags, _notes]) { c.dispose(); }

    super.dispose();
  }

  Map<String, dynamic> _buildPayload() => {
    'name': _name.text.trim(),
    'displayName': _displayName.text.trim(),
    'customerType': _customerType,
    if (_customerGroup.text.trim().isNotEmpty) 'customerGroup': _customerGroup.text.trim(),
    'gstin': _gstin.text.trim(),
    'pan': _pan.text.trim(),
    'isGSTRegistered': _isGSTRegistered,
    'isActive': _isActive,
    'contactPerson': _contactPerson.text.trim(),
    'mobile': _mobile.text.trim(),
    'email': _email.text.trim(),
    'altMobile': _altMobile.text.trim(),
    'website': _website.text.trim(),
    'addresses': _addresses.map((a) => a.toJson()).toList(),
    if (_paymentTerms != null && _paymentTerms!.isNotEmpty) 'paymentTerms': _paymentTerms,

    'creditLimit': double.tryParse(_creditLimit.text) ?? 0,
    'openingBalance': double.tryParse(_openingBalance.text) ?? 0,
    if (_openingBalanceDate != null) 'openingBalanceDate': _openingBalanceDate!.toIso8601String(),
    'discountPercent': double.tryParse(_discountPercent.text) ?? 0,
    'tags': _tags.text.trim().isEmpty ? [] : _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    'notes': _notes.text.trim(),
  };

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = _buildPayload();
    final provider = context.read<CustomerProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateCustomer(widget.customer!.id, payload);
    } else {
      success = await provider.createCustomer(payload) != null;
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
    final provider = context.watch<CustomerProvider>();
    final common = context.watch<CommonProvider>();
    final states = common.states;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Customer List'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Customer Information ──────────────────
              _section('CUSTOMER INFORMATION'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(controller: _name, label: 'Customer Name',
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _displayName, label: 'Display Name')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _dropdown('Customer Type', _customerType,
                    ['B2B', 'B2C', 'export'], (v) => setState(() => _customerType = v ?? 'B2B'))),

                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _customerGroup, label: 'Customer Group')),
              ]),

              // ── Tax & Contact ─────────────────────────
              const SizedBox(height: 28),
              _section('TAX & CONTACT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(controller: _gstin, label: 'GSTIN')),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _pan, label: 'PAN')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _checkbox('GST Registered', _isGSTRegistered, (v) => setState(() => _isGSTRegistered = v ?? false)),
                const SizedBox(width: 24),
                _checkbox('Active Customer', _isActive, (v) => setState(() => _isActive = v ?? true)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _contactPerson, label: 'Contact Person')),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _mobile, label: 'Mobile', keyboardType: TextInputType.phone)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _altMobile, label: 'Alternate Mobile', keyboardType: TextInputType.phone)),
              ]),
              const SizedBox(height: 14),
              AppTextField(controller: _website, label: 'Website', keyboardType: TextInputType.url),

              // ── Addresses ─────────────────────────────
              const SizedBox(height: 28),
              _section('ADDRESSES'),
              const SizedBox(height: 12),
              ..._addresses.asMap().entries.map((e) => _AddressCard(
                index: e.key,
                entry: e.value,
                states: states,
                canRemove: _addresses.length > 1,
                onRemove: () => setState(() => _addresses.removeAt(e.key)),
                onChanged: () => setState(() {}),
              )),
              TextButton.icon(
                onPressed: () => setState(() => _addresses.add(_AddressEntry())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Another Address'),
              ),

              // ── Commercial Details ─────────────────────
              const SizedBox(height: 28),
              _section('COMMERCIAL DETAILS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _nullableDropdown(
                  label: 'Payment Terms',
                  value: _paymentTerms,
                  items: _paymentTermsOptions,
                  hint: 'Select payment terms',
                  onChanged: (v) => setState(() => _paymentTerms = v),
                )),

                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _creditLimit, label: 'Credit Limit', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _openingBalance, label: 'Opening Balance', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _datePicker(context)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _discountPercent, label: 'Discount %', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _tags, label: 'Tags (comma separated)')),
              ]),
              const SizedBox(height: 14),
              AppTextField(controller: _notes, label: 'Notes', maxLines: 3),

              // ── Save ──────────────────────────────────
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : _onSave,
                  child: provider.isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_isEdit ? 'Update Customer' : 'Save Customer',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Text(title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 1.2));

  Widget _checkbox(String label, bool value, void Function(bool?) onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ]);

  Widget _dropdown(String label, String value, List<String> items, void Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);

  Widget _nullableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && items.contains(value)) ? value : null,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]);


  Widget _datePicker(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Opening Balance Date',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    const SizedBox(height: 8),
    InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: _openingBalanceDate ?? DateTime.now(),
          firstDate: DateTime(2000), lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _openingBalanceDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(_openingBalanceDate != null
              ? '${_openingBalanceDate!.day}-${_openingBalanceDate!.month}-${_openingBalanceDate!.year}'
              : 'dd-mm-yyyy',
              style: TextStyle(color: _openingBalanceDate != null
                  ? AppColors.textPrimary : AppColors.textHint)),
        ]),
      ),
    ),
  ]);
}

// ════════════════════════════════════════════════════
// Address entry data class
// ════════════════════════════════════════════════════
class _AddressEntry {
  final TextEditingController label;
  final TextEditingController line1;
  final TextEditingController line2;
  final TextEditingController city;
  final TextEditingController pinCode;
  final TextEditingController country;
  String selectedStateName;
  String selectedStateCode;
  bool isDefault;

  _AddressEntry({
    String labelText = '',
    String line1Text = '',
    String line2Text = '',
    String cityText = '',
    String pinText = '',
    String countryText = 'India',
    this.selectedStateName = '',
    this.selectedStateCode = '',
    this.isDefault = false,
  })  : label = TextEditingController(text: labelText),
        line1 = TextEditingController(text: line1Text),
        line2 = TextEditingController(text: line2Text),
        city = TextEditingController(text: cityText),
        pinCode = TextEditingController(text: pinText),
        country = TextEditingController(text: countryText);

  factory _AddressEntry.fromModel(CustomerAddress a) => _AddressEntry(
        labelText: a.label,
        line1Text: a.line1,
        line2Text: a.line2,
        cityText: a.city,
        pinText: a.pinCode,
        countryText: a.country,
        selectedStateName: a.state,
        selectedStateCode: a.stateCode,
        isDefault: a.isDefault,
      );

  Map<String, dynamic> toJson() => {
        'label': label.text.trim(),
        'line1': line1.text.trim(),
        'line2': line2.text.trim(),
        'city': city.text.trim(),
        'state': selectedStateName,
        'stateCode': selectedStateCode,
        'pinCode': pinCode.text.trim(),
        'country': country.text.trim().isEmpty ? 'India' : country.text.trim(),
        'isDefault': isDefault,
      };
}

// ════════════════════════════════════════════════════
// Address Card Widget
// ════════════════════════════════════════════════════
class _AddressCard extends StatefulWidget {
  final int index;
  final _AddressEntry entry;
  final List<StateItem> states;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _AddressCard({
    required this.index,
    required this.entry,
    required this.states,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<_AddressCard> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Address ${widget.index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          if (widget.canRemove)
            TextButton(onPressed: widget.onRemove,
                child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: e.label, label: 'Label',
              hint: 'Billing Address')),
          const SizedBox(width: 16),
          Row(children: [
            Checkbox(value: e.isDefault, activeColor: AppColors.primary,
                onChanged: (v) => setState(() { e.isDefault = v ?? false; widget.onChanged(); })),
            const Text('Default address', style: TextStyle(fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: e.line1, label: 'Address Line 1')),
          const SizedBox(width: 16),
          Expanded(child: AppTextField(controller: e.line2, label: 'Address Line 2')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: e.city, label: 'City')),
          const SizedBox(width: 16),
          // State dropdown
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: widget.states.any((s) => s.name == e.selectedStateName) ? e.selectedStateName : null,
                  hint: const Text('Select a state', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                  items: widget.states.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (name) {
                    if (name == null) return;
                    final match = widget.states.firstWhere((s) => s.name == name);
                    setState(() { e.selectedStateName = match.name; e.selectedStateCode = match.code; });
                  },
                ),
              ),
            ),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: e.pinCode, label: 'PIN Code', keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: AppTextField(controller: e.country, label: 'Country')),
        ]),
      ]),
    );
  }
}
