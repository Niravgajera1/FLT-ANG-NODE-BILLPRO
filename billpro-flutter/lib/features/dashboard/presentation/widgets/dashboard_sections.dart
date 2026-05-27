import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

/// Section header with title and optional "View All" action.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Summary — Receivables / Payables / Overdue
// ─────────────────────────────────────────────────────────────────────────────

class FinancialSummaryCards extends StatelessWidget {
  final DashboardKpis kpis;

  const FinancialSummaryCards({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                title: 'Receivables',
                value: formatCurrencyFull(kpis.netReceivable.value),
                subtitle: '${formatCurrencyFull(kpis.netReceivable.overdue ?? 0)} overdue',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                title: 'Payables',
                value: formatCurrencyFull(kpis.netPayable.value),
                subtitle: '${formatCurrencyFull(kpis.netPayable.overdue ?? 0)} overdue',
                icon: Icons.payments_outlined,
                color: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          title: 'Overdue Invoices',
          value: '${kpis.overdueInvoices.value.toInt()}',
          subtitle: '${formatCurrencyFull(kpis.overdueInvoices.overdue ?? 0)} outstanding',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Access Grid
// ─────────────────────────────────────────────────────────────────────────────

class QuickAccessGrid extends StatelessWidget {
  final void Function(String route) onNavigate;

  const QuickAccessGrid({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QAItem(Icons.add_circle_outline_rounded, 'New Invoice', const Color(0xFF2563EB), '/sales'),
      _QAItem(Icons.receipt_long_rounded, 'Sales', const Color(0xFFD97706), '/sales'),
      _QAItem(Icons.shopping_cart_outlined, 'Purchases', const Color(0xFF0284C7), '/purchases'),
      _QAItem(Icons.people_alt_outlined, 'Customers', const Color(0xFF059669), '/customers'),
      _QAItem(Icons.local_shipping_outlined, 'Vendors', const Color(0xFFE11D48), '/vendors'),
      _QAItem(Icons.inventory_2_outlined, 'Products', const Color(0xFF7C3AED), '/items'),
      _QAItem(Icons.person_outline_rounded, 'Profile', const Color(0xFF6366F1), '/profile'),
      _QAItem(Icons.more_horiz_rounded, 'More', const Color(0xFF64748B), '/profile'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onNavigate(item.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QAItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  _QAItem(this.icon, this.label, this.color, this.route);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom info cards — Top Customers / Top Products / Invoice Status
// ─────────────────────────────────────────────────────────────────────────────

class TopCustomersMini extends StatelessWidget {
  final List<TopCustomer> customers;

  const TopCustomersMini({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return _emptyInfo('No customer revenue yet.', Icons.people_outlined);
    }
    return Column(
      children: customers.take(5).map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF059669).withValues(alpha: 0.1),
                child: Text(
                  c.customerName.isNotEmpty ? c.customerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${c.invoiceCount} invoice${c.invoiceCount != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(c.totalRevenue),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class TopProductsMini extends StatelessWidget {
  final List<TopSellingProduct> products;

  const TopProductsMini({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _emptyInfo('No product sales yet.', Icons.inventory_2_outlined);
    }
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFE11D48),
    ];

    return Column(
      children: products.take(5).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final color = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Qty: ${p.totalQuantity}  •  Avg: ${formatCurrency(p.avgUnitPrice)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(p.totalRevenue),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class InvoiceStatusMini extends StatelessWidget {
  final List<InvoiceStatusItem> items;

  const InvoiceStatusMini({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _emptyInfo('No invoice status data.', Icons.pie_chart_outline);
    }

    return Column(
      children: items.map((item) {
        final color = statusColor(item.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  formatStatus(item.status),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${item.count}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  formatCurrency(item.value),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Widget _emptyInfo(String message, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// Info card wrapper used in the bottom section.
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
