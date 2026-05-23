import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/item_model.dart';
import '../providers/item_provider.dart';
import 'add_edit_item_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});
  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  void _onTab() {
    if (_tabCtrl.indexIsChanging) return;
    final p = context.read<ItemProvider>();
    switch (_tabCtrl.index) {
      case 0: p.setFilter(ItemFilter.all); break;
      case 1: p.setFilter(ItemFilter.product); break;
      case 2: p.setFilter(ItemFilter.service); break;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.removeListener(_onTab);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ItemProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Product Catalogue',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Item'),
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
          child: Column(children: [
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
                  controller: _searchCtrl,
                  onChanged: (v) => context.read<ItemProvider>().search(v),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, code, brand...',
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
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: 'All (${p.totalCount})'),
                const Tab(text: 'Products'),
                const Tab(text: 'Services'),
              ],
            ),
          ]),
        ),
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<ItemProvider>().loadItems(),
              child: p.items.isEmpty
                  ? _EmptyState(
                      hasSearch: _searchCtrl.text.isNotEmpty,
                      onAdd: () => _openForm(context, null),
                    )
                  : Column(children: [
                      // Stats strip
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          _Stat(label: 'TOTAL', value: '${p.totalCount}', color: AppColors.textPrimary),
                          _divider(),
                          _Stat(label: 'LOW STOCK', value: '${p.lowStockCount}', color: const Color(0xFFD97706)),
                          _divider(),
                          _Stat(label: 'INACTIVE', value: '${p.inactiveCount}', color: AppColors.textSecondary),
                        ]),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: p.items.length,
                          itemBuilder: (ctx, i) {
                            final item = p.items[i];
                            return _ItemCard(
                              item: item,
                              onEdit: () => _openForm(context, item),
                              onToggle: () => _confirmToggle(context, item),
                            );
                          },
                        ),
                      ),
                    ]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16));

  Future<void> _openForm(BuildContext context, ItemModel? item) async {
    final p = context.read<ItemProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: AddEditItemPage(item: item),
      )),
    );
    if (result == true && mounted) {
      AppToast.showOnMessenger(messenger,
          message: item == null ? 'Item added!' : 'Item updated!',
          type: ToastType.success);
    }
  }

  Future<void> _confirmToggle(BuildContext context, ItemModel item) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.read<ItemProvider>();
    final wasActive = item.isActive;

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
            child: Icon(wasActive ? Icons.inventory_2_outlined : Icons.inventory_2_rounded,
                color: wasActive ? AppColors.error : AppColors.success, size: 28),
          ),
          const SizedBox(height: 16),
          Text(wasActive ? 'Deactivate Item?' : 'Activate Item?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            wasActive ? '"${item.name}" will be marked inactive.' : '"${item.name}" will be activated.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: wasActive ? AppColors.error : AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(wasActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            )),
          ]),
        ]),
      ),
    );

    if (confirmed == true && mounted) {
      await p.toggleActive(item);
      AppToast.showOnMessenger(messenger,
          message: wasActive ? 'Item deactivated' : 'Item activated',
          type: ToastType.info);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────
// Stat chip
// ──────────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 1.1)),
  ]));
}

// ──────────────────────────────────────────────────────────────────────
// Item Card
// ──────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  const _ItemCard({required this.item, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isProduct = item.itemType == 'product';
    final isActive = item.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowStock
              ? const Color(0xFFFDE68A)
              : (isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5)),
          width: item.isLowStock ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Row 1: Icon + Name + Type badge ──
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isProduct ? AppColors.primarySoft : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProduct ? Icons.inventory_2_outlined : Icons.design_services_outlined,
                  color: isProduct ? AppColors.primary : const Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(item.name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // Low stock badge
                  if (item.isLowStock)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Low Stock',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706))),
                    ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  if (item.itemCode != null)
                    Text(item.itemCode!, style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint, fontFamily: 'monospace')),
                  const Spacer(),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isProduct ? AppColors.primarySoft : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isProduct ? 'Product' : 'Service',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isProduct ? AppColors.primary : const Color(0xFF7C3AED))),
                  ),
                ]),
              ])),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // ── Row 2: Pricing ──
            Row(children: [
              _priceChip('SELLING', '₹${_fmt(item.sellingPrice)}', AppColors.success),
              const SizedBox(width: 10),
              _priceChip('PURCHASE', '₹${_fmt(item.purchasePrice)}', AppColors.textSecondary),
              const SizedBox(width: 10),
              _priceChip('GST', '${item.gstRate.toStringAsFixed(0)}%', AppColors.textPrimary),
            ]),

            // ── Row 3: Stock (only for products tracking inventory) ──
            if (item.trackInventory && isProduct) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.warehouse_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Stock: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('${item.currentStock.toStringAsFixed(0)} ${item.unit}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: item.isLowStock ? const Color(0xFFD97706) : AppColors.textPrimary,
                    )),
                if (item.category != null) ...[
                  const Spacer(),
                  const Icon(Icons.category_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(item.category!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ]),
            ] else if (item.category != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.category_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(item.category!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Row 4: Status + Actions ──
            Row(children: [
              // Status tap
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF0FDF4) : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
                    ),
                  ),
                  child: Row(children: [
                    Icon(isActive ? Icons.circle : Icons.circle_outlined,
                        size: 8, color: isActive ? AppColors.success : AppColors.textHint),
                    const SizedBox(width: 5),
                    Text(isActive ? 'Active' : 'Inactive',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.success : AppColors.textSecondary)),
                  ]),
                ),
              ),
              if (item.isSelling) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Selling', style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: AppColors.success)),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _priceChip(String label, String value, Color color) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 1.1)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ],
  ));

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ──────────────────────────────────────────────────────────────────────
// Empty State
// ──────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;
  const _EmptyState({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) => ListView(children: [
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Icon(hasSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 52, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(hasSearch ? 'No items found' : 'No items yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(hasSearch ? 'Try a different search term' : 'Start by adding your first product or service',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
        if (!hasSearch) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('Add First Item'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ]),
    ),
  ]);
}
