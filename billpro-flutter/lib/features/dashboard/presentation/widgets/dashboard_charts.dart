import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';
import 'dashboard_helpers.dart';

/// Sales Trend line chart — Sales + Tax lines by month.
class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendItem> data;

  const SalesTrendChart({super.key, required this.data});

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sales and tax collected by month',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data.length} month(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF2563EB), 'Sales'),
              const SizedBox(width: 20),
              _legend(const Color(0xFF059669), 'Tax'),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 200,
            child: data.isEmpty ? _emptyChart() : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxSales =
        data.fold<double>(0, (p, e) => e.sales > p ? e.sales : p);
    final maxTax =
        data.fold<double>(0, (p, e) => e.taxAmount > p ? e.taxAmount : p);
    final maxY = (maxSales > maxTax ? maxSales : maxTax) * 1.2;
    final effectiveMaxY = maxY > 0 ? maxY : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: effectiveMaxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    formatCurrency(value),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthName(data[index].month),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: effectiveMaxY,
        lineBarsData: [
          // Sales line
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.sales))
                .toList(),
            isCurved: true,
            color: const Color(0xFF2563EB),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF2563EB),
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            ),
          ),
          // Tax line
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.taxAmount))
                .toList(),
            isCurved: true,
            color: const Color(0xFF059669),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF059669),
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF059669).withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final color = spot.barIndex == 0
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF059669);
              final label = spot.barIndex == 0 ? 'Sales' : 'Tax';
              return LineTooltipItem(
                '$label: ${formatCurrency(spot.y)}',
                TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _emptyChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 0.2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toStringAsFixed(1)}',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textHint),
                );
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 1,
        lineBarsData: [],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Sales vs Purchases bar chart — grouped bars by month.
class SalesVsPurchaseChart extends StatelessWidget {
  final SalesVsPurchase data;

  const SalesVsPurchaseChart({super.key, required this.data});

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales vs Purchases',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Revenue compared with purchase spend',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'FY view',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF2563EB), 'Sales'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFD97706), 'Purchases'),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 200,
            child: _hasData() ? _buildChart() : _emptyChart(),
          ),
        ],
      ),
    );
  }

  bool _hasData() {
    return data.salesData.isNotEmpty || data.purchaseData.isNotEmpty;
  }

  Widget _buildChart() {
    // Build a unified list of months
    final months = <int>{};
    for (final s in data.salesData) {
      months.add(s.month);
    }
    for (final p in data.purchaseData) {
      months.add(p.month);
    }
    final sortedMonths = months.toList()..sort();

    if (sortedMonths.isEmpty) return _emptyChart();

    double maxY = 0;
    for (final s in data.salesData) {
      if (s.total > maxY) maxY = s.total;
    }
    for (final p in data.purchaseData) {
      if (p.total > maxY) maxY = p.total;
    }
    maxY = maxY * 1.2;
    if (maxY <= 0) maxY = 1.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  formatCurrency(value),
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textHint),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedMonths.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthName(sortedMonths[index]),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedMonths.asMap().entries.map((entry) {
          final index = entry.key;
          final month = entry.value;
          final sales = data.salesData
              .where((s) => s.month == month)
              .fold<double>(0, (p, s) => p + s.total);
          final purchases = data.purchaseData
              .where((p) => p.month == month)
              .fold<double>(0, (prev, p) => prev + p.total);

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sales,
                color: const Color(0xFF2563EB),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: purchases,
                color: const Color(0xFFD97706),
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Sales' : 'Purchases';
              final color = rodIndex == 0
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD97706);
              return BarTooltipItem(
                '$label: ${formatCurrency(rod.toY)}',
                TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 0.2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toStringAsFixed(1)}',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textHint),
                );
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        maxY: 1,
        barGroups: [],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
