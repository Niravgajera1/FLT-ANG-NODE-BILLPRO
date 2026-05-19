import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/providers/common_provider.dart';
import '../../data/models/company_model.dart';
import '../providers/profile_provider.dart';

class EditCompanyPage extends StatefulWidget {
  final CompanyModel? company;
  final bool isCreateMode;

  const EditCompanyPage({
    super.key,
    this.company,
    this.isCreateMode = false,
  });

  @override
  State<EditCompanyPage> createState() => _EditCompanyPageState();
}

class _EditCompanyPageState extends State<EditCompanyPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _legalName;
  late final TextEditingController _tradeName;
  late final TextEditingController _industryType;
  late final TextEditingController _gstin;
  late final TextEditingController _pan;
  late final TextEditingController _fssaiNumber;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _website;
  late final TextEditingController _addrLine1;
  late final TextEditingController _addrLine2;
  late final TextEditingController _addrCity;
  late final TextEditingController _addrPinCode;

  // Dropdown values
  late String _businessType;
  late String _businessCategory;
  late String _gstType;
  late String _selectedStateName;
  late String _selectedStateCode;
  late bool _isGSTRegistered;
  late bool _tcsEnabled;
  late bool _tdsEnabled;
  late int _fyStartMonth;

  // Bank account controllers
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountHolder;
  late final TextEditingController _bankAccountNumber;
  late final TextEditingController _bankIfsc;
  late final TextEditingController _bankBranch;
  late final TextEditingController _bankBranchAddress;
  late final TextEditingController _bankUpi;
  late String _bankAccountType;

  @override
  void initState() {
    super.initState();
    final c = widget.company;

    _legalName = TextEditingController(text: c?.legalName ?? '');
    _tradeName = TextEditingController(text: c?.tradeName ?? '');
    _industryType = TextEditingController(text: c?.industryType ?? '');
    _gstin = TextEditingController(text: c?.gstin ?? '');
    _pan = TextEditingController(text: c?.pan ?? '');
    _fssaiNumber = TextEditingController(text: c?.fssaiNumber ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _mobile = TextEditingController(text: c?.mobile ?? '');
    _website = TextEditingController(text: c?.website ?? '');
    _addrLine1 = TextEditingController(text: c?.registeredAddress?.line1 ?? '');
    _addrLine2 = TextEditingController(text: c?.registeredAddress?.line2 ?? '');
    _addrCity = TextEditingController(text: c?.registeredAddress?.city ?? '');
    _addrPinCode =
        TextEditingController(text: c?.registeredAddress?.pinCode ?? '');

    _businessType = c?.businessType ?? '';
    _businessCategory = c?.businessCategory ?? '';
    _gstType = c?.gstType ?? 'regular';
    _selectedStateName = c?.registeredAddress?.state ?? '';
    _selectedStateCode = c?.registeredAddress?.stateCode ?? '';
    _isGSTRegistered = c?.isGSTRegistered ?? false;
    _tcsEnabled = c?.tcsEnabled ?? false;
    _tdsEnabled = c?.tdsEnabled ?? false;
    _fyStartMonth = c?.fyStartMonth ?? 4;

    final bank = (c?.bankAccounts.isNotEmpty ?? false) ? c!.bankAccounts.first : null;
    _bankName = TextEditingController(text: bank?.bankName ?? '');
    _bankAccountHolder =
        TextEditingController(text: bank?.accountHolderName ?? '');
    _bankAccountNumber =
        TextEditingController(text: bank?.accountNumber ?? '');
    _bankIfsc = TextEditingController(text: bank?.ifscCode ?? '');
    _bankBranch = TextEditingController(text: bank?.branchName ?? '');
    _bankBranchAddress =
        TextEditingController(text: bank?.branchAddress ?? '');
    _bankUpi = TextEditingController(text: bank?.upiId ?? '');
    _bankAccountType = bank?.accountType ?? 'current';

    // Fetch dropdown data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommonProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _legalName, _tradeName, _industryType,
      _gstin, _pan, _fssaiNumber, _email, _mobile, _website,
      _addrLine1, _addrLine2, _addrCity, _addrPinCode,
      _bankName, _bankAccountHolder, _bankAccountNumber, _bankIfsc,
      _bankBranch, _bankBranchAddress, _bankUpi,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'legalName': _legalName.text.trim(),
      'tradeName': _tradeName.text.trim(),
      'businessType': _businessType,
      'businessCategory': _businessCategory,
      'industryType': _industryType.text.trim(),
      'gstin': _gstin.text.trim(),
      'pan': _pan.text.trim(),
      'fssaiNumber': _fssaiNumber.text.trim(),
      'gstType': _gstType,
      'isGSTRegistered': _isGSTRegistered,
      'tcsEnabled': _tcsEnabled,
      'tdsEnabled': _tdsEnabled,
      'email': _email.text.trim(),
      'mobile': _mobile.text.trim(),
      'website': _website.text.trim(),
      'fyStartMonth': _fyStartMonth,
      'registeredAddress': {
        'line1': _addrLine1.text.trim(),
        'line2': _addrLine2.text.trim(),
        'city': _addrCity.text.trim(),
        'state': _selectedStateName,
        'stateCode': _selectedStateCode,
        'pinCode': _addrPinCode.text.trim(),
        'country': 'India',
      },
      'bankAccounts': [
        if (_bankName.text.trim().isNotEmpty)
          {
            'bankName': _bankName.text.trim(),
            'accountHolderName': _bankAccountHolder.text.trim(),
            'accountNumber': _bankAccountNumber.text.trim(),
            'ifscCode': _bankIfsc.text.trim(),
            'accountType': _bankAccountType,
            'branchName': _bankBranch.text.trim(),
            'branchAddress': _bankBranchAddress.text.trim(),
            'upiId': _bankUpi.text.trim(),
            'isDefault': true,
          },
      ],
    };
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_businessType.isEmpty) {
      AppToast.show(context, message: 'Please select Business Type', type: ToastType.error);
      return;
    }
    if (_businessCategory.isEmpty) {
      AppToast.show(context, message: 'Please select Business Category', type: ToastType.error);
      return;
    }
    if (_selectedStateName.isEmpty) {
      AppToast.show(context, message: 'Please select State', type: ToastType.error);
      return;
    }

    final payload = _buildPayload();
    final profile = context.read<ProfileProvider>();

    bool success;
    if (widget.isCreateMode) {
      final result = await profile.createCompany(payload);
      success = result != null;
    } else {
      success = await profile.updateCompany(payload);
    }

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      AppToast.show(context,
          message: profile.errorMessage ?? 'Operation failed',
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final common = context.watch<CommonProvider>();
    final isCreate = widget.isCreateMode;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(isCreate ? 'Add Business' : 'Edit Company',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: common.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Basic Information ───────────────────────
                    _sectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _legalName,
                      label: 'Legal Name',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _tradeName, label: 'Trade Name'),
                    const SizedBox(height: 14),

                    _buildApiDropdown(
                      label: 'Business Type',
                      value: _businessType,
                      items: common.businessTypes,
                      onChanged: (v) =>
                          setState(() => _businessType = v ?? ''),
                    ),
                    const SizedBox(height: 14),

                    _buildApiDropdown(
                      label: 'Business Category',
                      value: _businessCategory,
                      items: common.businessCategories,
                      onChanged: (v) =>
                          setState(() => _businessCategory = v ?? ''),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                        controller: _industryType, label: 'Industry Type'),

                    // ─── Tax & Compliance ────────────────────────
                    const SizedBox(height: 28),
                    _sectionTitle('Tax & Compliance'),
                    const SizedBox(height: 12),
                    AppTextField(controller: _gstin, label: 'GSTIN'),
                    const SizedBox(height: 14),
                    AppTextField(controller: _pan, label: 'PAN'),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _fssaiNumber, label: 'FSSAI Number'),
                    const SizedBox(height: 14),

                    _buildApiDropdown(
                      label: 'GST Type',
                      value: _gstType,
                      items: common.gstTypes,
                      onChanged: (v) =>
                          setState(() => _gstType = v ?? 'regular'),
                    ),
                    const SizedBox(height: 14),

                    _buildSwitch('GST Registered', _isGSTRegistered,
                        (v) => setState(() => _isGSTRegistered = v)),
                    _buildSwitch('TCS Enabled', _tcsEnabled,
                        (v) => setState(() => _tcsEnabled = v)),
                    _buildSwitch('TDS Enabled', _tdsEnabled,
                        (v) => setState(() => _tdsEnabled = v)),

                    // ─── Contact ─────────────────────────────────
                    const SizedBox(height: 28),
                    _sectionTitle('Contact'),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _mobile,
                        label: 'Mobile',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _website,
                        label: 'Website',
                        keyboardType: TextInputType.url),

                    // ─── Registered Address ──────────────────────
                    const SizedBox(height: 28),
                    _sectionTitle('Registered Address'),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _addrLine1, label: 'Address Line 1'),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _addrLine2, label: 'Address Line 2'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                              controller: _addrCity, label: 'City'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                              controller: _addrPinCode,
                              label: 'PIN Code',
                              keyboardType: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildStateDropdown(common.states),

                    // ─── Financial Year ──────────────────────────
                    const SizedBox(height: 28),
                    _sectionTitle('Financial Year'),
                    const SizedBox(height: 12),
                    _buildApiDropdown(
                      label: 'FY Start Month',
                      value: _fyStartMonth.toString(),
                      items: List.generate(12, (i) => '${i + 1}'),
                      displayLabels: const [
                        'January', 'February', 'March', 'April',
                        'May', 'June', 'July', 'August',
                        'September', 'October', 'November', 'December',
                      ],
                      onChanged: (v) => setState(
                          () => _fyStartMonth = int.parse(v ?? '4')),
                    ),

                    // ─── Bank Account ────────────────────────────
                    const SizedBox(height: 28),
                    _sectionTitle('Bank Account'),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _bankName, label: 'Bank Name'),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _bankAccountHolder,
                        label: 'Account Holder'),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _bankAccountNumber,
                        label: 'Account Number',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _bankIfsc, label: 'IFSC Code'),
                    const SizedBox(height: 14),
                    _buildApiDropdown(
                      label: 'Account Type',
                      value: _bankAccountType,
                      items: const ['current', 'savings'],
                      onChanged: (v) =>
                          setState(() => _bankAccountType = v ?? 'current'),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _bankBranch, label: 'Branch Name'),
                    const SizedBox(height: 14),
                    AppTextField(
                        controller: _bankBranchAddress,
                        label: 'Branch Address'),
                    const SizedBox(height: 14),
                    AppTextField(controller: _bankUpi, label: 'UPI ID'),

                    // ─── Save Button ─────────────────────────────
                    const SizedBox(height: 36),
                    Consumer<ProfileProvider>(
                      builder: (context, profile, _) {
                        return AppButton(
                          text: isCreate ? 'Create Business' : 'Save Changes',
                          isLoading: profile.isUpdating,
                          onPressed: _onSave,
                          icon: isCreate
                              ? Icons.add_business_rounded
                              : Icons.save_rounded,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ──────────────── Helpers ────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary));
  }

  Widget _buildApiDropdown({
    required String label,
    required String value,
    required List<String> items,
    List<String>? displayLabels,
    required void Function(String?) onChanged,
  }) {
    final effectiveItems = items.contains(value)
        ? items
        : [if (value.isNotEmpty) value, ...items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary.withValues(alpha: 0.8))),
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
              value: effectiveItems.contains(value) ? value : null,
              isExpanded: true,
              hint: Text('Select $label',
                  style: const TextStyle(color: AppColors.textHint)),
              items: effectiveItems.asMap().entries.map((e) {
                final displayText = (displayLabels != null &&
                        items.contains(e.value) &&
                        items.indexOf(e.value) < displayLabels.length)
                    ? displayLabels[items.indexOf(e.value)]
                    : e.value;
                return DropdownMenuItem(
                  value: e.value,
                  child: Text(displayText),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown(List<StateItem> states) {
    String? currentValue;
    if (_selectedStateName.isNotEmpty) {
      final exists = states.any((s) => s.name == _selectedStateName);
      if (exists) currentValue = _selectedStateName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary.withValues(alpha: 0.8))),
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
              value: currentValue,
              isExpanded: true,
              hint: const Text('Select State',
                  style: TextStyle(color: AppColors.textHint)),
              items: states
                  .map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text('${s.name} (${s.code})'),
                      ))
                  .toList(),
              onChanged: (name) {
                if (name == null) return;
                final match = states.firstWhere((s) => s.name == name);
                setState(() {
                  _selectedStateName = match.name;
                  _selectedStateCode = match.code;
                });
              },
            ),
          ),
        ),
        if (_selectedStateCode.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('State Code: $_selectedStateCode',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildSwitch(
      String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            thumbColor: WidgetStatePropertyAll(value ? Colors.white : null),
          ),
        ],
      ),
    );
  }
}
