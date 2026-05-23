import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/common_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/company_model.dart';
import '../providers/profile_provider.dart';
import 'edit_company_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── 1. GET /auth/me → refresh user
  // ── 2. GET /companies → backend resolves company from auth token
  // ── 3. No company → hasNoCompany = true → show "Add Business"
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _profileLoading = true);

    // Step 1 — refresh user from /auth/me
    final auth = context.read<AuthProvider>();
    await auth.refreshProfile();

    // Step 2 — load company (no companyId needed, resolved from token)
    if (mounted) {
      await context.read<ProfileProvider>().loadCompanyDetails();
    }

    if (mounted) setState(() => _profileLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'User Details'),
            Tab(text: 'Business Details'),
          ],
        ),
      ),
      body: _profileLoading || user == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _UserDetailsTab(user: user, auth: auth),
                _BusinessDetailsTab(onRefresh: _loadData),
              ],
            ),
    );
  }
}

// ════════════════════════════════════════════════════
// TAB 1 — User Details (read-only from /auth/me)
// ════════════════════════════════════════════════════
class _UserDetailsTab extends StatelessWidget {
  final dynamic user;
  final AuthProvider auth;
  const _UserDetailsTab({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Avatar card ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Info grid ────────────────────────────────
          _DetailGrid(items: [
            _Item('Full Name', user.fullName),
            _Item('Email', user.email),
            _Item('Mobile', user.mobile),
            _Item('Role', user.role.replaceAll('_', ' ')),
            _Item('Email Verified', user.isEmailVerified ? 'Yes ✓' : 'No'),
            _Item(
                'Mobile Verified', user.isMobileVerified ? 'Yes ✓' : 'No'),
            _Item('Account Active', user.isActive ? 'Yes' : 'No'),
            _Item('Onboarding',
                user.onboardingCompleted ? 'Completed' : 'Pending'),
          ]),

          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TAB 2 — Business Details
// GET /companies?companyId=<id>
// POST /companies (create)
// PUT  /companies?companyId=<id> (update)
// ════════════════════════════════════════════════════
class _BusinessDetailsTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _BusinessDetailsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final auth = context.read<AuthProvider>();

    // Loading state
    if (profile.isLoadingCompany) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── No company → Add Business ──────────────────
    if (profile.hasNoCompany || profile.company == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Business Registered',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up your company profile to start\ncreating GST invoices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openForm(context, null, auth, profile, onRefresh),
                  icon: const Icon(Icons.add_business_rounded, size: 20),
                  label: const Text('Add Business'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Company exists → Show details ──────────────
    final c = profile.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Company Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _openForm(context, c, auth, profile, onRefresh),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Business info grid
          _DetailGrid(items: [
            _Item('Legal Name', c.legalName),
            _Item('Trade Name', c.tradeName),
            _Item('Business Type', c.businessType),
            _Item('Business Category', c.businessCategory ?? 'N/A'),
            _Item('Industry Type', c.industryType ?? 'N/A'),
            _Item('GSTIN', c.gstin ?? 'N/A'),
            _Item('PAN', c.pan ?? 'N/A'),
            _Item('FSSAI Number', c.fssaiNumber ?? 'N/A'),
            _Item('GST Type', c.gstType ?? 'N/A'),
            _Item('GST Registered', c.isGSTRegistered ? 'Yes' : 'No'),
            _Item('TCS Enabled', c.tcsEnabled ? 'Yes' : 'No'),
            _Item('TDS Enabled', c.tdsEnabled ? 'Yes' : 'No'),
            _Item('Email', c.email ?? 'N/A'),
            _Item('Mobile', c.mobile ?? 'N/A'),
            _Item('Website', c.website ?? 'N/A'),
            _Item('FY Start Month', 'Month ${c.fyStartMonth}'),
          ]),

          const SizedBox(height: 20),

          // Registered Address
          if (c.registeredAddress != null) ...[
            const Text(
              'Registered Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.registeredAddress!.line1 != null &&
                      c.registeredAddress!.line1!.isNotEmpty)
                    Text(c.registeredAddress!.line1!,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  if (c.registeredAddress!.line2 != null &&
                      c.registeredAddress!.line2!.isNotEmpty)
                    Text(c.registeredAddress!.line2!,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      c.registeredAddress!.city,
                      c.registeredAddress!.pinCode,
                    ].where((e) => e != null && e.isNotEmpty).join(', '),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                  ),
                  Text(
                    [
                      c.registeredAddress!.state,
                      c.registeredAddress!.stateCode != null
                          ? '(${c.registeredAddress!.stateCode})'
                          : null,
                    ].where((e) => e != null && e.isNotEmpty).join(' '),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  Text(c.registeredAddress!.country ?? 'India',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],

          // Bank Accounts
          if (c.bankAccounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bank Accounts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${c.bankAccounts.length} account(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...c.bankAccounts.map((bank) => _BankCard(bank: bank)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Navigate to EditCompanyPage and reload on success
  void _openForm(
    BuildContext context,
    CompanyModel? company,
    AuthProvider auth,
    ProfileProvider profile,
    VoidCallback onRefresh,
  ) async {
    final common = context.read<CommonProvider>();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profile),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: common),
          ],
          child: EditCompanyPage(
            company: company,
            isCreateMode: company == null,
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      // Reload everything after create/update
      onRefresh();
      AppToast.show(
        context,
        message: company == null
            ? 'Business created successfully!'
            : 'Business updated successfully!',
        type: ToastType.success,
      );
    }
  }
}

// ════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════
class _DetailGrid extends StatelessWidget {
  final List<_Item> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 52) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        AppColors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Item {
  final String label;
  final String value;
  const _Item(this.label, this.value);
}

class _BankCard extends StatelessWidget {
  final BankAccount bank;
  const _BankCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.bankName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      bank.accountType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (bank.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          _row('Account Holder', bank.accountHolderName),
          _row('Account No.', bank.accountNumber),
          _row('IFSC', bank.ifscCode),
          if (bank.branchName != null && bank.branchName!.isNotEmpty)
            _row('Branch', bank.branchName!),
          if (bank.upiId != null && bank.upiId!.isNotEmpty)
            _row('UPI ID', bank.upiId!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
