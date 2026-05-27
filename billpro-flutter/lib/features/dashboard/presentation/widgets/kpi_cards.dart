import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Horizontally-scrollable KPI chip cards (modern fintech / banking style)
// ─────────────────────────────────────────────────────────────────────────────

class KpiScrollRow extends StatelessWidget {
  final DashboardKpis kpis;

  const KpiScrollRow({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        label: 'Total Sales',
        value: formatCurrencyFull(kpis.totalSales.value),
        subtitle: '${formatCurrencyFull(kpis.totalSales.prevValue ?? 0)} prev',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF16A34A),
        gradient: const [Color(0xFF16A34A), Color(0xFF22D3EE)],
      ),
      _KpiData(
        label: 'Total Purchases',
        value: formatCurrencyFull(kpis.totalPurchases.value),
        subtitle: '${formatCurrencyFull(kpis.totalPurchases.prevValue ?? 0)} prev',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFE11D48),
        gradient: const [Color(0xFFE11D48), Color(0xFFF97316)],
      ),
      _KpiData(
        label: 'Gross Profit',
        value: formatCurrencyFull(kpis.grossProfit.value),
        subtitle: 'This period',
        icon: kpis.grossProfit.value >= 0
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        color: const Color(0xFFD97706),
        gradient: const [Color(0xFFD97706), Color(0xFFFBBF24)],
      ),
      _KpiData(
        label: 'Net Receivable',
        value: formatCurrencyFull(kpis.netReceivable.value),
        subtitle: '${formatCurrencyFull(kpis.netReceivable.overdue ?? 0)} overdue',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF2563EB),
        gradient: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
      ),
      _KpiData(
        label: 'Net Payable',
        value: formatCurrencyFull(kpis.netPayable.value),
        subtitle: '${formatCurrencyFull(kpis.netPayable.overdue ?? 0)} overdue',
        icon: Icons.payments_outlined,
        color: const Color(0xFF7C3AED),
        gradient: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
      ),
      _KpiData(
        label: 'GST Payable',
        value: formatCurrencyFull(kpis.gstPayable.value),
        subtitle: 'Current liability',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF059669),
        gradient: const [Color(0xFF059669), Color(0xFF14B8A6)],
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _KpiChipCard(data: items[index]),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  _KpiData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class _KpiChipCard extends StatelessWidget {
  final _KpiData data;
  const _KpiChipCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.gradient[0].withValues(alpha: 0.08),
            data.gradient[1].withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.color),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: data.color,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat row — Invoices / Bills / Customers / Vendors counts
// ─────────────────────────────────────────────────────────────────────────────

class QuickStatsStrip extends StatelessWidget {
  final DashboardKpis kpis;

  const QuickStatsStrip({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _QStat(Icons.receipt_rounded, 'Invoices',
          kpis.totalInvoices.value.toInt().toString(), const Color(0xFF2563EB)),
      _QStat(Icons.description_rounded, 'Bills',
          kpis.totalBills.value.toInt().toString(), const Color(0xFF0284C7)),
      _QStat(Icons.people_rounded, 'Customers',
          kpis.activeCustomers.value.toInt().toString(), const Color(0xFF059669)),
      _QStat(Icons.local_shipping_rounded, 'Vendors',
          kpis.activeVendors.value.toInt().toString(), const Color(0xFFD97706)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats
            .map((s) => _QStatItem(stat: s))
            .toList(),
      ),
    );
  }
}

class _QStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _QStat(this.icon, this.label, this.value, this.color);
}

class _QStatItem extends StatelessWidget {
  final _QStat stat;
  const _QStatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(stat.icon, color: stat.color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          stat.value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: stat.color,
          ),
        ),
        Text(
          stat.label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
