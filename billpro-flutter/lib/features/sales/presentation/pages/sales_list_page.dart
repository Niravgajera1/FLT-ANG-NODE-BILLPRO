import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/sales_model.dart';
import '../providers/sales_provider.dart';
import 'add_edit_sales_page.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});
  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SalesProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sales Invoices',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Invoice'),
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
          preferredSize: const Size.fromHeight(60),
          child: Padding(
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
                onChanged: (v) => context.read<SalesProvider>().search(v),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search customer, invoice no...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
              ),
            ),
          ),
        ),
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<SalesProvider>().loadInvoices(),
              child: p.invoices.isEmpty
                  ? _EmptyState(
                      hasSearch: _searchCtrl.text.isNotEmpty,
                      onAdd: () => _openForm(context),
                    )
                  : Column(children: [
                      // Stats strip
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          _Stat(label: 'TOTAL INVOICES', value: '${p.totalInvoices}', color: AppColors.textPrimary),
                          _divider(),
                          _Stat(label: 'DUE INVOICES', value: '${p.dueInvoices}', color: const Color(0xFFD97706)),
                        ]),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Consumer<SalesProvider>(
                          builder: (ctx, sp, _) => ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: sp.invoices.length,
                            itemBuilder: (ctx, i) {
                              final invoice = sp.invoices[i];
                              return _InvoiceCard(
                                invoice: invoice,
                                isPdfLoading: sp.isPdfLoading && sp.pdfLoadingId == invoice.id,
                                onView: () => sp.downloadPdf(invoice.id),
                                onEdit: () => _openForm(context, invoice),
                                onDelete: () => _confirmDelete(context, invoice),
                              );
                            },
                          ),
                        ),
                      ),
                    ]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16));

  Future<void> _openForm(BuildContext context, [SalesInvoiceModel? invoice]) async {
    final p = context.read<SalesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: AddEditSalesPage(invoice: invoice),
      )),
    );
    if (result == true && mounted) {
      AppToast.showOnMessenger(messenger,
          message: invoice == null ? 'Invoice created successfully!' : 'Invoice updated successfully!',
          type: ToastType.success);
    }
  }

  Future<void> _confirmDelete(BuildContext context, SalesInvoiceModel invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.read<SalesProvider>();

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
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFF1F2),
            child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Delete Invoice?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Invoice ${invoice.invoiceNumber} will be permanently deleted. This action cannot be undone.',
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
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
            )),
          ]),
        ]),
      ),
    );

    if (confirmed == true && mounted) {
      final success = await p.deleteInvoice(invoice.id);
      if (success) {
        AppToast.showOnMessenger(messenger, message: 'Invoice deleted', type: ToastType.success);
      } else {
        AppToast.showOnMessenger(messenger, message: p.errorMessage ?? 'Delete failed', type: ToastType.error);
      }
    }
  }
}

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

class _InvoiceCard extends StatelessWidget {
  final SalesInvoiceModel invoice;
  final bool isPdfLoading;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceCard({required this.invoice, this.isPdfLoading = false, required this.onView, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Parse date quickly for UI
    String dateStr = invoice.invoiceDate;
    if (dateStr.length >= 10) dateStr = dateStr.substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(invoice.customerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: invoice.status == 'saved' ? AppColors.success.withValues(alpha: 0.1) : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(invoice.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: invoice.status == 'saved' ? AppColors.success : AppColors.primary)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
              const Spacer(),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Text('₹${invoice.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ])),
              InkWell(
                onTap: isPdfLoading ? null : onView,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                  child: isPdfLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

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
          child: Icon(hasSearch ? Icons.search_off_rounded : Icons.receipt_long_rounded,
              size: 52, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(hasSearch ? 'No invoices found' : 'No invoices yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(hasSearch ? 'Try a different search term' : 'Start by creating your first sales invoice',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
        if (!hasSearch) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('Add Invoice'),
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
