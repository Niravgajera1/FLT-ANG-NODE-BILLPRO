import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/common_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/vendor_model.dart';
import '../providers/vendor_provider.dart';

class AddEditVendorPage extends StatefulWidget {
  final VendorModel? vendor;
  const AddEditVendorPage({super.key, this.vendor});

  @override
  State<AddEditVendorPage> createState() => _AddEditVendorPageState();
}

class _AddEditVendorPageState extends State<AddEditVendorPage> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.vendor != null;

  // Basic
  late final TextEditingController _name;
  late final TextEditingController _displayName;

  // Tax & Contact
  late final TextEditingController _gstin;
  late final TextEditingController _pan;
  late final TextEditingController _contactPerson;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late bool _isGSTRegistered;
  late bool _isActive;
  late bool _isRCMApplicable;

  // Addresses
  late _AddressEntry _registeredAddress;
  late _AddressEntry _billingAddress;
  bool _sameAsRegistered = false;

  // Commercial
  late String? _paymentTerms;
  late final TextEditingController _creditLimit;
  late final TextEditingController _openingBalance;
  late final TextEditingController _tags;
  late final TextEditingController _notes;

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
    final v = widget.vendor;
    _name = TextEditingController(text: v?.name ?? '');
    _displayName = TextEditingController(text: v?.displayName ?? '');
    _gstin = TextEditingController(text: v?.gstin ?? '');
    _pan = TextEditingController(text: v?.pan ?? '');
    _contactPerson = TextEditingController(text: v?.contactPerson ?? '');
    _mobile = TextEditingController(text: v?.mobile ?? '');
    _email = TextEditingController(text: v?.email ?? '');
    _isGSTRegistered = v?.isGSTRegistered ?? false;
    _isActive = v?.isActive ?? true;
    _isRCMApplicable = v?.isRCMApplicable ?? false;

    _registeredAddress = v != null ? _AddressEntry.fromModel(v.registeredAddress) : _AddressEntry();
    _billingAddress = v != null ? _AddressEntry.fromModel(v.billingAddress) : _AddressEntry();

    _paymentTerms = (_paymentTermsOptions.contains(v?.paymentTerms))
        ? v?.paymentTerms
        : null;

    _creditLimit = TextEditingController(text: v?.creditLimit.toStringAsFixed(0) ?? '0');
    _openingBalance = TextEditingController(text: v?.openingBalance.toStringAsFixed(0) ?? '0');
    _tags = TextEditingController(text: v?.tags.join(', ') ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommonProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _displayName, _gstin, _pan,
      _contactPerson, _mobile, _email,
      _creditLimit, _openingBalance,
      _tags, _notes]) { c.dispose(); }

    _registeredAddress.dispose();
    _billingAddress.dispose();
    super.dispose();
  }

  void _syncAddresses() {
    if (_sameAsRegistered) {
      _billingAddress.line1.text = _registeredAddress.line1.text;
      _billingAddress.line2.text = _registeredAddress.line2.text;
      _billingAddress.city.text = _registeredAddress.city.text;
      _billingAddress.state = _registeredAddress.state;
      _billingAddress.stateCode.text = _registeredAddress.stateCode.text;
      _billingAddress.pinCode.text = _registeredAddress.pinCode.text;
      setState(() {});
    }
  }

  Map<String, dynamic> _buildPayload() => {
    'name': _name.text.trim(),
    'displayName': _displayName.text.trim(),
    'gstin': _gstin.text.trim(),
    'pan': _pan.text.trim(),
    'isGSTRegistered': _isGSTRegistered,
    'isRCMApplicable': _isRCMApplicable,
    'isActive': _isActive,
    'contactPerson': _contactPerson.text.trim(),
    'mobile': _mobile.text.trim(),
    'email': _email.text.trim(),
    'registeredAddress': _registeredAddress.toJson(),
    'billingAddress': _billingAddress.toJson(),
    if (_paymentTerms != null && _paymentTerms!.isNotEmpty) 'paymentTerms': _paymentTerms,
    'creditLimit': double.tryParse(_creditLimit.text) ?? 0,
    'openingBalance': double.tryParse(_openingBalance.text) ?? 0,
    'tags': _tags.text.trim().isEmpty ? [] : _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    'notes': _notes.text.trim(),
  };

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = _buildPayload();
    final provider = context.read<VendorProvider>();
    bool success;
    if (_isEdit) {
      success = await provider.updateVendor(widget.vendor!.id, payload);
    } else {
      success = await provider.createVendor(payload) != null;
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
    final provider = context.watch<VendorProvider>();
    final common = context.watch<CommonProvider>();
    final states = common.states;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Vendor' : 'Add Vendor',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vendor Information ──────────────────
              _section('VENDOR INFORMATION'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(controller: _name, label: 'Vendor Name *',
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _displayName, label: 'Display Name')),
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
                _checkbox('RCM Applicable', _isRCMApplicable, (v) => setState(() => _isRCMApplicable = v ?? false)),
                const SizedBox(width: 24),
                _checkbox('Active Vendor', _isActive, (v) => setState(() => _isActive = v ?? true)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(controller: _contactPerson, label: 'Contact Person')),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(controller: _mobile, label: 'Mobile', keyboardType: TextInputType.phone)),
              ]),
              const SizedBox(height: 14),
              AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress),

              // ── Addresses ─────────────────────────────
              const SizedBox(height: 28),
              _section('REGISTERED ADDRESS'),
              const SizedBox(height: 12),
              _AddressCard(
                entry: _registeredAddress,
                states: states,
                onChanged: () {
                  setState(() {});
                  _syncAddresses();
                },
              ),
              
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _section('BILLING ADDRESS')),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _sameAsRegistered,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          setState(() => _sameAsRegistered = v ?? false);
                          _syncAddresses();
                        },
                      ),
                      const Text('Same as Registered', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_sameAsRegistered)
                _AddressCard(
                  entry: _billingAddress,
                  states: states,
                  onChanged: () => setState(() {}),
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
                      : Text(_isEdit ? 'Update Vendor' : 'Save Vendor',
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

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textHint, letterSpacing: 1.2),
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _nullableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
      const SizedBox(height: 8),
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }
}

class _AddressEntry {
  final TextEditingController line1 = TextEditingController();
  final TextEditingController line2 = TextEditingController();
  final TextEditingController city = TextEditingController();
  String? state;
  final TextEditingController stateCode = TextEditingController();
  final TextEditingController pinCode = TextEditingController();

  _AddressEntry();

  factory _AddressEntry.fromModel(VendorAddress address) {
    final e = _AddressEntry();
    e.line1.text = address.line1;
    e.line2.text = address.line2;
    e.city.text = address.city;
    e.state = address.state.isNotEmpty ? address.state : null;
    e.stateCode.text = address.stateCode;
    e.pinCode.text = address.pinCode;
    return e;
  }

  Map<String, dynamic> toJson() => {
    'line1': line1.text.trim(),
    'line2': line2.text.trim(),
    'city': city.text.trim(),
    'state': state ?? '',
    'stateCode': stateCode.text.trim(),
    'pinCode': pinCode.text.trim(),
    'country': 'India',
  };

  void dispose() {
    line1.dispose();
    line2.dispose();
    city.dispose();
    stateCode.dispose();
    pinCode.dispose();
  }
}

class _AddressCard extends StatelessWidget {
  final _AddressEntry entry;
  final List<dynamic> states;
  final VoidCallback onChanged;

  const _AddressCard({
    required this.entry,
    required this.states,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppTextField(controller: entry.line1, label: 'Line 1'),
          const SizedBox(height: 12),
          AppTextField(controller: entry.line2, label: 'Line 2'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(controller: entry.city, label: 'City')),
            const SizedBox(width: 16),
            Expanded(child: AppTextField(controller: entry.pinCode, label: 'Pin Code', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('State', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select state', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                      value: entry.state,
                      items: states.map((s) => DropdownMenuItem<String>(
                          value: s.name, child: Text(s.name, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) {
                        entry.state = v;
                        final selected = states.firstWhere((s) => s.name == v, orElse: () => null);
                        if (selected != null) {
                          entry.stateCode.text = selected.code;
                        }
                        onChanged();
                      },
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(child: AppTextField(controller: entry.stateCode, label: 'State Code')),
          ]),
        ],
      ),
    );
  }
}
