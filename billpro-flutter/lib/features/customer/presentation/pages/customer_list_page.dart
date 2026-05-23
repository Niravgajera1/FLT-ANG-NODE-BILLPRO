import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'add_edit_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final p = context.read<CustomerProvider>();
      switch (_tabController.index) {
        case 0: p.setFilter(CustomerFilter.all); break;
        case 1: p.setFilter(CustomerFilter.active); break;
        case 2: p.setFilter(CustomerFilter.inactive); break;
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
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Customers',
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
              // Search bar
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
                    onChanged: (v) => context.read<CustomerProvider>().search(v),
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
              // Tabs
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
              onRefresh: () => context.read<CustomerProvider>().loadCustomers(),
              child: provider.customers.isEmpty
                  ? _EmptyState(
                      hasSearch: _searchController.text.isNotEmpty,
                      onAdd: () => _openForm(context, null),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: provider.customers.length,
                      itemBuilder: (context, i) {
                        final c = provider.customers[i];
                        return _CustomerCard(
                          customer: c,
                          onEdit: () => _openForm(context, c),
                          onToggle: () => _confirmToggle(context, c),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, CustomerModel? customer) async {
    final provider = context.read<CustomerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: AddEditCustomerPage(customer: customer),
      )),
    );
    if (result == true && mounted) {
      AppToast.showOnMessenger(messenger,
          message: customer == null ? 'Customer added!' : 'Customer updated!',
          type: ToastType.success);
    }
  }

  Future<void> _confirmToggle(BuildContext context, CustomerModel c) async {
    // Capture before async gap
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<CustomerProvider>();
    final wasActive = c.isActive;

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
          Text(wasActive ? 'Deactivate Customer?' : 'Activate Customer?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            wasActive
                ? '${c.name} will be marked as inactive.'
                : '${c.name} will be activated again.',
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
      await provider.toggleActive(c);
      AppToast.showOnMessenger(messenger,
          message: wasActive ? 'Customer deactivated' : 'Customer activated',
          type: ToastType.info);
    }
  }
}

// ════════════════════════════════════════════════════
// Customer Card — mobile optimised
// ════════════════════════════════════════════════════
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final addr = customer.defaultAddress;
    final isActive = customer.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Avatar + Name + Status badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isActive
                        ? AppColors.primarySoft
                        : AppColors.bgSurface,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + code + type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: customer.customerType == 'B2B'
                                    ? AppColors.primarySoft
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                customer.customerType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: customer.customerType == 'B2B'
                                      ? AppColors.primary
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (customer.displayName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(customer.displayName,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                        if (customer.customerCode != null) ...[
                          const SizedBox(height: 4),
                          Text(customer.customerCode!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontFamily: 'monospace')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),

              // ── Row 2: Contact info ───────────────────
              if (customer.contactPerson != null || customer.mobile != null)
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  if (customer.contactPerson != null)
                    Text('${customer.contactPerson}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  const Spacer(),
                  if (customer.mobile != null)
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(customer.mobile!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ]),
                ]),

              if (customer.email != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.email_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(customer.email!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ],

              if (addr != null) ...[
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                      '${addr.city}, ${addr.state} - ${addr.pinCode}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ],

              const SizedBox(height: 12),

              // ── Row 3: Credit + Status + Actions ─────
              Row(
                children: [
                  // Credit limit chip
                  if (customer.creditLimit > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.credit_card_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('₹${_fmt(customer.creditLimit)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ]),
                    ),

                  const Spacer(),

                  // Status toggle
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFF0FDF4)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          isActive ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: isActive ? AppColors.success : AppColors.textHint,
                        ),
                        const SizedBox(width: 5),
                        Text(isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.success : AppColors.textSecondary,
                            )),
                      ]),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Edit button
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ════════════════════════════════════════════════════
// Empty state
// ════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;
  const _EmptyState({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSearch ? Icons.search_off_rounded : Icons.people_alt_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasSearch ? 'No customers found' : 'No customers yet',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'Try a different name or mobile number'
                    : 'Start by adding your first customer',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              if (!hasSearch) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add First Customer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
