import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/vendor_model.dart';
import '../providers/vendor_provider.dart';
import 'add_edit_vendor_page.dart';

class VendorListPage extends StatefulWidget {
  const VendorListPage({super.key});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().loadVendors();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final p = context.read<VendorProvider>();
      switch (_tabController.index) {
        case 0: p.setFilter(VendorFilter.all); break;
        case 1: p.setFilter(VendorFilter.active); break;
        case 2: p.setFilter(VendorFilter.inactive); break;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vendors',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => context.read<VendorProvider>().search(v),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, mobile, email...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      filled: false,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'All (${provider.totalCount})'),
                  Tab(text: 'Active (${provider.activeCount})'),
                  Tab(text: 'Inactive (${provider.inactiveCount})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<VendorProvider>().loadVendors(),
              child: provider.vendors.isEmpty
                  ? _EmptyState(
                      hasSearch: _searchController.text.isNotEmpty,
                      onAdd: () => _openForm(context, null),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: provider.vendors.length,
                      itemBuilder: (context, i) {
                        final v = provider.vendors[i];
                        return _VendorCard(
                          vendor: v,
                          onEdit: () => _openForm(context, v),
                          onToggle: () => _confirmToggle(context, v),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Vendor', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, VendorModel? vendor) async {
    final provider = context.read<VendorProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: AddEditVendorPage(vendor: vendor),
      )),
    );
    if (result == true && mounted) {
      AppToast.showOnMessenger(messenger,
          message: vendor == null ? 'Vendor added!' : 'Vendor updated!',
          type: ToastType.success);
    }
  }

  Future<void> _confirmToggle(BuildContext context, VendorModel v) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<VendorProvider>();
    final wasActive = v.isActive;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 28,
            backgroundColor: wasActive ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
            child: Icon(wasActive ? Icons.person_off_rounded : Icons.person_rounded,
                color: wasActive ? AppColors.error : AppColors.success, size: 28),
          ),
          const SizedBox(height: 16),
          Text(wasActive ? 'Deactivate Vendor?' : 'Activate Vendor?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            wasActive
                ? '${v.name} will be marked as inactive.'
                : '${v.name} will be activated again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: wasActive ? AppColors.error : AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(wasActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );

    if (confirmed == true && mounted) {
      await provider.toggleActive(v);
      AppToast.showOnMessenger(messenger,
          message: wasActive ? 'Vendor deactivated' : 'Vendor activated',
          type: ToastType.success);
    }
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _VendorCard({
    required this.vendor,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        vendor.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vendor.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: vendor.isActive
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: vendor.isActive
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFFECDD3),
                                  ),
                                ),
                                child: Text(
                                  vendor.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: vendor.isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (vendor.vendorCode != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              vendor.vendorCode!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgMain,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.receipt_long_rounded,
                          label: 'GSTIN',
                          value: vendor.gstin?.isNotEmpty == true ? vendor.gstin! : 'N/A',
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _InfoItem(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Balance',
                            value: '₹${vendor.openingBalance.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onToggle,
                      icon: Icon(
                        vendor.isActive ? Icons.person_off_rounded : Icons.person_rounded,
                        size: 18,
                        color: vendor.isActive ? AppColors.error : AppColors.success,
                      ),
                      label: Text(
                        vendor.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                          color: vendor.isActive ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyState({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'No vendors found' : 'No vendors yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try adjusting your search criteria.'
                  : 'Add your first vendor to start managing them.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
