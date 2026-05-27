import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Recent Sales Invoices — card-based mobile layout
// ─────────────────────────────────────────────────────────────────────────────

class RecentInvoicesList extends StatelessWidget {
  final List<RecentSalesInvoice> invoices;

  const RecentInvoicesList({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return _emptyState('No recent invoices found.', Icons.receipt_long_outlined);
    }
    return Column(
      children: invoices.map((inv) => _InvoiceTile(invoice: inv)).toList(),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final RecentSalesInvoice invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final sColor = statusColor(invoice.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 16, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              // Invoice number + customer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      invoice.customerName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrencyFull(invoice.grandTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatStatus(invoice.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: sColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bottom row
          Row(
            children: [
              _miniTag(Icons.calendar_today_outlined,
                  'Due: ${formatDate(invoice.dueDate)}'),
              const Spacer(),
              if (invoice.balanceDue > 0)
                _miniTag(Icons.account_balance_wallet_outlined,
                    'Bal: ${formatCurrency(invoice.balanceDue)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Purchase Bills — card-based mobile layout
// ─────────────────────────────────────────────────────────────────────────────

class RecentBillsList extends StatelessWidget {
  final List<RecentPurchaseBill> bills;

  const RecentBillsList({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return _emptyState('No recent purchase bills found.', Icons.shopping_cart_outlined);
    }
    return Column(
      children: bills.map((bill) => _BillTile(bill: bill)).toList(),
    );
  }
}

class _BillTile extends StatelessWidget {
  final RecentPurchaseBill bill;
  const _BillTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final sColor = statusColor(bill.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    size: 16, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 10),
              // Bill number + vendor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      bill.vendorName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrencyFull(bill.grandTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatStatus(bill.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: sColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bottom row
          Row(
            children: [
              _miniTag(Icons.calendar_today_outlined,
                  'Due: ${formatDate(bill.dueDate)}'),
              const Spacer(),
              if (bill.balanceDue > 0)
                _miniTag(Icons.account_balance_wallet_outlined,
                    'Bal: ${formatCurrency(bill.balanceDue)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state placeholder
// ─────────────────────────────────────────────────────────────────────────────

Widget _emptyState(String message, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
