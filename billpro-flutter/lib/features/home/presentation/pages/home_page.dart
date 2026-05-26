import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/kpi_cards.dart';
import '../../../dashboard/presentation/widgets/dashboard_sections.dart';
import '../../../dashboard/presentation/widgets/dashboard_lists.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data on first visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      if (!provider.hasData && !provider.isLoading) {
        provider.loadSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dash, _) {
            if (dash.isLoading && !dash.hasData) {
              return _buildShimmerLoading();
            }

            if (dash.errorMessage != null && !dash.hasData) {
              return _buildErrorState(dash);
            }

            if (!dash.hasData) {
              return _buildShimmerLoading();
            }

            final data = dash.summary!;

            return RefreshIndicator(
              onRefresh: () => dash.loadSummary(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // ── Financial Overview Gradient Card ────
                    _buildOverviewCard(data),
                    const SizedBox(height: 20),

                    // ── Quick Stats Row ─────────────────────
                    QuickStatsRow(kpis: data.kpis),
                    const SizedBox(height: 24),

                    // ── KPI Grid ────────────────────────────
                    SectionHeader(
                      title: 'Financial KPIs',
                      icon: Icons.analytics_rounded,
                    ),
                    const SizedBox(height: 12),
                    KpiGrid(kpis: data.kpis),
                    const SizedBox(height: 24),

                    // ── Sales vs Purchase ────────────────────
                    SectionHeader(
                      title: 'Sales vs Purchase',
                      icon: Icons.compare_arrows_rounded,
                    ),
                    const SizedBox(height: 12),
                    SalesVsPurchaseCard(kpis: data.kpis),
                    const SizedBox(height: 24),

                    // ── Invoice Status ──────────────────────
                    if (data.invoiceStatus.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Invoice Status',
                        icon: Icons.pie_chart_rounded,
                      ),
                      const SizedBox(height: 12),
                      InvoiceStatusCard(items: data.invoiceStatus),
                      const SizedBox(height: 24),
                    ],

                    // ── Top Selling Products ────────────────
                    if (data.topSellingProducts.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Top Selling Products',
                        icon: Icons.star_rounded,
                        onViewAll: () => context.push('/items'),
                      ),
                      const SizedBox(height: 12),
                      TopProductsList(products: data.topSellingProducts),
                      const SizedBox(height: 24),
                    ],

                    // ── Top Customers ───────────────────────
                    if (data.topCustomers.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Top Customers',
                        icon: Icons.emoji_events_rounded,
                        onViewAll: () => context.push('/customers'),
                      ),
                      const SizedBox(height: 12),
                      TopCustomersList(customers: data.topCustomers),
                      const SizedBox(height: 24),
                    ],

                    // ── Recent Sales Invoices ───────────────
                    if (data.recentSalesInvoices.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Recent Invoices',
                        icon: Icons.receipt_long_rounded,
                        onViewAll: () => context.push('/sales'),
                      ),
                      const SizedBox(height: 12),
                      RecentInvoicesList(
                          invoices: data.recentSalesInvoices),
                      const SizedBox(height: 24),
                    ],

                    // ── Recent Purchase Bills ───────────────
                    if (data.recentPurchaseBills.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Recent Purchase Bills',
                        icon: Icons.shopping_cart_rounded,
                        onViewAll: () => context.push('/purchases'),
                      ),
                      const SizedBox(height: 12),
                      RecentBillsList(bills: data.recentPurchaseBills),
                      const SizedBox(height: 24),
                    ],

                    // ── Quick Access ────────────────────────
                    SectionHeader(
                      title: 'Quick Access',
                      icon: Icons.apps_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAccess(context),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'FY ${_currentFY()} Overview',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            _headerButton(Icons.refresh_rounded, () {
              context.read<DashboardProvider>().loadSummary();
            }),
            const SizedBox(width: 8),
            _headerButton(Icons.person_outline_rounded, () {
              context.push('/profile');
            }),
          ],
        ),
      ],
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }

  String _currentFY() {
    final now = DateTime.now();
    final start = now.month >= 4 ? now.year : now.year - 1;
    final end = start + 1;
    return '$start-${end.toString().substring(2)}';
  }

  // ─── Overview Gradient Card ──────────────────────────────────────────────

  Widget _buildOverviewCard(dynamic data) {
    final kpis = data.kpis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Business Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _overviewStat(
                  'Total Sales',
                  _formatLarge(kpis.totalSales.value),
                  Icons.trending_up_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _overviewStat(
                  'Total Purchases',
                  _formatLarge(kpis.totalPurchases.value),
                  Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  kpis.grossProfit.value >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: kpis.grossProfit.value >= 0
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Gross Profit: ${_formatLarge(kpis.grossProfit.value)}',
                  style: TextStyle(
                    color: kpis.grossProfit.value >= 0
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLarge(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    String result;
    if (absVal >= 10000000) {
      result = '₹${(absVal / 10000000).toStringAsFixed(2)} Cr';
    } else if (absVal >= 100000) {
      result = '₹${(absVal / 100000).toStringAsFixed(2)} L';
    } else if (absVal >= 1000) {
      result = '₹${(absVal / 1000).toStringAsFixed(1)}K';
    } else {
      result = '₹${absVal.toStringAsFixed(0)}';
    }
    return isNegative ? '-$result' : result;
  }

  // ─── Quick Access Grid ─────────────────────────────────────────────────

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      (Icons.receipt_long_rounded, 'Sales', const Color(0xFFD97706), '/sales'),
      (Icons.shopping_cart_rounded, 'Purchases', const Color(0xFF0284C7), '/purchases'),
      (Icons.people_alt_rounded, 'Customers', AppColors.primary, '/customers'),
      (Icons.local_shipping_rounded, 'Vendors', const Color(0xFFE11D48), '/vendors'),
      (Icons.inventory_2_rounded, 'Products', const Color(0xFF059669), '/items'),
      (Icons.business_rounded, 'Profile', const Color(0xFF7C3AED), '/profile'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => context.push(item.$4),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.$3.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.$1, color: item.$3, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Loading Shimmer ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          // Gradient card placeholder
          _shimmerBox(height: 180, borderRadius: 20),
          const SizedBox(height: 20),
          // Stats row
          _shimmerBox(height: 90, borderRadius: 16),
          const SizedBox(height: 24),
          // KPI grid
          Row(children: [
            Expanded(child: _shimmerBox(height: 110, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(height: 110, borderRadius: 16)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _shimmerBox(height: 110, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(height: 110, borderRadius: 16)),
          ]),
          const SizedBox(height: 24),
          _shimmerBox(height: 140, borderRadius: 16),
          const SizedBox(height: 24),
          _shimmerBox(height: 100, borderRadius: 16),
          const SizedBox(height: 12),
          _shimmerBox(height: 100, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double borderRadius = 12}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value > 0.65 ? 1.3 - value : 0.3 + value,
          child: child,
        );
      },
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(DashboardProvider dash) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              dash.errorMessage ?? 'Failed to load dashboard',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => dash.loadSummary(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
