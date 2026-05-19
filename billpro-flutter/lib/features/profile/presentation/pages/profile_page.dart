import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/providers/common_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../data/models/company_model.dart';
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

  Future<void> _loadData() async {
    setState(() => _profileLoading = true);

    // 1. Call GET /auth/me for fresh user data
    final auth = context.read<AuthProvider>();
    await auth.refreshProfile();

    // 2. Load company if user has one
    if (mounted) {
      final user = auth.user;
      final profile = context.read<ProfileProvider>();
      if (user != null && user.companies.isNotEmpty) {
        final companyId =
            user.activeCompanyId ?? user.companies.first.companyId;
        await profile.loadCompanyDetails(companyId);
      } else {
        // New user — no companies
        await profile.loadCompanyDetails(null);
      }
    }

    if (mounted) setState(() => _profileLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Profile',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
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
                _buildUserTab(context, user, auth),
                _buildBusinessTab(context, profile, auth),
              ],
            ),
    );
  }

  // ──────────────── User Details Tab ────────────────
  Widget _buildUserTab(BuildContext context, dynamic user, AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar Card
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
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
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
                        letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Cards (read-only profile info from /auth/me)
          _buildDetailGrid([
            _DetailItem('Full Name', user.fullName),
            _DetailItem('Email', user.email),
            _DetailItem('Mobile', user.mobile),
            _DetailItem('Role', user.role.replaceAll('_', ' ')),
            _DetailItem(
                'Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
            _DetailItem(
                'Mobile Verified', user.isMobileVerified ? 'Yes' : 'No'),
            _DetailItem('Account Active', user.isActive ? 'Yes' : 'No'),
            _DetailItem('Onboarding',
                user.onboardingCompleted ? 'Completed' : 'Pending'),
          ]),

          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Logout',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
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

  // ──────────────── Business Details Tab ────────────────
  Widget _buildBusinessTab(
      BuildContext context, ProfileProvider profile, AuthProvider auth) {
    if (profile.isLoadingCompany) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── No company — show Add Business button ──
    if (profile.hasNoCompany || profile.company == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_center_outlined,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('No Business Registered',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Set up your company profile to start\ncreating GST invoices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCompanyForm(
                      context: context, company: null, auth: auth),
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

    // ── Company exists — show details ──
    final c = profile.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Company Profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: () =>
                    _openCompanyForm(context: context, company: c, auth: auth),
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

          // Company Info Grid
          _buildDetailGrid([
            _DetailItem('Legal Name', c.legalName),
            _DetailItem('Trade Name', c.tradeName),
            _DetailItem('Business Type', c.businessType),
            _DetailItem('Business Category', c.businessCategory ?? 'N/A'),
            _DetailItem('Industry Type', c.industryType ?? 'N/A'),
            _DetailItem('GSTIN', c.gstin ?? 'N/A'),
            _DetailItem('PAN', c.pan ?? 'N/A'),
            _DetailItem('FSSAI Number', c.fssaiNumber ?? 'N/A'),
            _DetailItem('GST Type', c.gstType ?? 'N/A'),
            _DetailItem('GST Registered', c.isGSTRegistered ? 'Yes' : 'No'),
            _DetailItem('TCS Enabled', c.tcsEnabled ? 'Yes' : 'No'),
            _DetailItem('TDS Enabled', c.tdsEnabled ? 'Yes' : 'No'),
            _DetailItem('Email', c.email ?? 'N/A'),
            _DetailItem('Mobile', c.mobile ?? 'N/A'),
            _DetailItem('Website', c.website ?? 'N/A'),
          ]),

          const SizedBox(height: 20),

          // Address Card
          if (c.registeredAddress != null) ...[
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
                  Text('REGISTERED ADDRESS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(c.registeredAddress!.line1 ?? '',
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
                      '${c.registeredAddress!.city ?? ''}, ${c.registeredAddress!.pinCode ?? ''}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                  Text(
                      '${c.registeredAddress!.state ?? ''} – ${c.registeredAddress!.stateCode ?? ''}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  Text(c.registeredAddress!.country ?? 'India',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          _buildDetailGrid([
            _DetailItem('Financial Year Start', 'Month ${c.fyStartMonth}'),
          ]),

          const SizedBox(height: 20),

          // Bank Accounts
          if (c.bankAccounts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bank Accounts',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${c.bankAccounts.length} account(s)',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...c.bankAccounts.map((bank) => _buildBankCard(bank)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────── Open company form (create or edit) ────────────────
  void _openCompanyForm({
    required BuildContext context,
    required CompanyModel? company,
    required AuthProvider auth,
  }) async {
    final profileProvider = context.read<ProfileProvider>();
    final commonProvider = context.read<CommonProvider>();
    final nav = Navigator.of(context);
    final result = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileProvider),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: commonProvider),
          ],
          child: EditCompanyPage(
            company: company,
            isCreateMode: company == null,
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      // Refresh profile to update companies list
      await auth.refreshProfile();
      final user = auth.user;
      if (user != null && user.companies.isNotEmpty) {
        final companyId =
            user.activeCompanyId ?? user.companies.first.companyId;
        await profileProvider.loadCompanyDetails(companyId);
      }
      if (mounted) {
        // ignore: use_build_context_synchronously
        AppToast.show(context,
            message: company == null
                ? 'Business created successfully!'
                : 'Business updated successfully!',
            type: ToastType.success);
      }
    }
  }

  // ──────────────── Helpers ────────────────

  Widget _buildBankCard(BankAccount bank) {
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
                    Text(bank.bankName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(bank.accountType.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8)),
                  ],
                ),
              ),
              if (bank.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Default',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A))),
                ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border)),
          _buildBankRow('Account Holder', bank.accountHolderName),
          _buildBankRow('Account No.', bank.accountNumber),
          _buildBankRow('IFSC', bank.ifscCode),
          if (bank.branchName != null && bank.branchName!.isNotEmpty)
            _buildBankRow('Branch', bank.branchName!),
          if (bank.upiId != null && bank.upiId!.isNotEmpty)
            _buildBankRow('UPI ID', bank.upiId!),
        ],
      ),
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(List<_DetailItem> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 52) / 2,
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
                Text(item.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(item.value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}
