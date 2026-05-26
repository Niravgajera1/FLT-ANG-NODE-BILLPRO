import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

/// A visually rich KPI card with icon, value, and optional subtitle.
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Widget? trailing;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// The grid of KPI cards at the top of the dashboard.
class KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;

  const KpiGrid({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        title: 'Total Sales',
        value: formatCurrency(kpis.totalSales.value),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF16A34A),
      ),
      _KpiItem(
        title: 'Total Purchases',
        value: formatCurrency(kpis.totalPurchases.value),
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF0284C7),
      ),
      _KpiItem(
        title: 'Gross Profit',
        value: formatCurrency(kpis.grossProfit.value),
        icon: kpis.grossProfit.value >= 0
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        color: kpis.grossProfit.value >= 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
      ),
      _KpiItem(
        title: 'Net Receivable',
        value: formatCurrency(kpis.netReceivable.value),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFD97706),
        subtitle: kpis.netReceivable.overdue != null && kpis.netReceivable.overdue! > 0
            ? 'Overdue: ${formatCurrency(kpis.netReceivable.overdue!)}'
            : null,
      ),
      _KpiItem(
        title: 'Net Payable',
        value: formatCurrency(kpis.netPayable.value),
        icon: Icons.payments_rounded,
        color: const Color(0xFFE11D48),
        subtitle: kpis.netPayable.overdue != null && kpis.netPayable.overdue! > 0
            ? 'Overdue: ${formatCurrency(kpis.netPayable.overdue!)}'
            : null,
      ),
      _KpiItem(
        title: 'GST Payable',
        value: formatCurrency(kpis.gstPayable.value),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KpiCard(
          title: item.title,
          value: item.value,
          icon: item.icon,
          color: item.color,
          subtitle: item.subtitle,
        );
      },
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}
