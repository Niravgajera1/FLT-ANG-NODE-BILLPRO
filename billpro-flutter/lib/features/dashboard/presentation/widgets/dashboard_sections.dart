import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

/// Compact stat chips for invoices, bills, customers, vendors.
class QuickStatsRow extends StatelessWidget {
  final DashboardKpis kpis;

  const QuickStatsRow({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(Icons.receipt_rounded, 'Invoices', kpis.totalInvoices.value.toInt().toString(), const Color(0xFF2563EB)),
      _Stat(Icons.description_rounded, 'Bills', kpis.totalBills.value.toInt().toString(), const Color(0xFF0284C7)),
      _Stat(Icons.people_rounded, 'Customers', kpis.activeCustomers.value.toInt().toString(), const Color(0xFF059669)),
      _Stat(Icons.local_shipping_rounded, 'Vendors', kpis.activeVendors.value.toInt().toString(), const Color(0xFFD97706)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) => _StatItem(stat: s)).toList(),
      ),
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _Stat(this.icon, this.label, this.value, this.color);
}

class _StatItem extends StatelessWidget {
  final _Stat stat;
  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(stat.icon, color: stat.color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          stat.value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: stat.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Section header with a title and optional "View All" action.
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
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View All', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

/// Sales vs Purchase comparison bar.
class SalesVsPurchaseCard extends StatelessWidget {
  final DashboardKpis kpis;

  const SalesVsPurchaseCard({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final sales = kpis.totalSales.value;
    final purchases = kpis.totalPurchases.value;
    final maxVal = sales > purchases ? sales : purchases;
    final salesFraction = maxVal > 0 ? sales / maxVal : 0.0;
    final purchaseFraction = maxVal > 0 ? purchases / maxVal : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar('Sales', formatCurrency(sales), salesFraction,
              const Color(0xFF16A34A)),
          const SizedBox(height: 16),
          _bar('Purchases', formatCurrency(purchases), purchaseFraction,
              const Color(0xFF0284C7)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gross Profit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: kpis.grossProfit.value >= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              Text(
                formatCurrency(kpis.grossProfit.value),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: kpis.grossProfit.value >= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, String value, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
