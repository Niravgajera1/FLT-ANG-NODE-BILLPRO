import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/kpi_cards.dart';
import '../../../dashboard/presentation/widgets/dashboard_sections.dart';
import '../../../dashboard/presentation/widgets/dashboard_lists.dart';
import '../../../dashboard/presentation/widgets/dashboard_charts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting Banner ─────────────────────
                    Consumer<DashboardProvider>(
                      builder: (ctx, d, _) => _buildGreetingBanner(ctx, d.isLoading),
                    ),

                    const SizedBox(height: 16),

                    // ── KPI Scroll Row ──────────────────────
                    KpiScrollRow(kpis: data.kpis),

                    const SizedBox(height: 16),

                    // ── Quick Stats Strip ───────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: QuickStatsStrip(kpis: data.kpis),
                    ),

                    const SizedBox(height: 20),

                    // ── Quick Access ────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        title: 'Quick Access',
                        icon: Icons.apps_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: QuickAccessGrid(
                        onNavigate: (route) => context.push(route),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Financial Summary ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        title: 'Financial Summary',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FinancialSummaryCards(kpis: data.kpis),
                    ),

                    const SizedBox(height: 20),

                    // ── Sales Trend Chart ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SalesTrendChart(data: data.salesTrend),
                    ),

                    const SizedBox(height: 12),

                    // ── Sales vs Purchases Chart ────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SalesVsPurchaseChart(
                          data: data.salesVsPurchase),
                    ),

                    const SizedBox(height: 20),

                    // ── Recent Sales Invoices ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        title: 'Recent Invoices',
                        icon: Icons.receipt_long_rounded,
                        onViewAll: () => context.push('/sales'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RecentInvoicesList(
                          invoices: data.recentSalesInvoices),
                    ),

                    const SizedBox(height: 16),

                    // ── Recent Purchase Bills ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader(
                        title: 'Recent Bills',
                        icon: Icons.shopping_cart_rounded,
                        onViewAll: () => context.push('/purchases'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                          RecentBillsList(bills: data.recentPurchaseBills),
                    ),

                    const SizedBox(height: 20),

                    // ── Top Customers ────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoCard(
                        title: 'Top Customers',
                        icon: Icons.emoji_events_rounded,
                        child: TopCustomersMini(
                            customers: data.topCustomers),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Top Products ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoCard(
                        title: 'Top Selling Products',
                        icon: Icons.star_rounded,
                        child: TopProductsMini(
                            products: data.topSellingProducts),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Invoice Status ───────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoCard(
                        title: 'Invoice Status',
                        icon: Icons.pie_chart_rounded,
                        child: InvoiceStatusMini(
                            items: data.invoiceStatus),
                      ),
                    ),

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

  // ─── Greeting Banner ────────────────────────────────────────────────────

  Widget _buildGreetingBanner(BuildContext context, [bool isRefreshing = false]) {
    final auth = context.read<AuthProvider>();
    final firstName = (auth.user?.fullName ?? '').split(' ').first;
    final greeting = _getGreeting();

    final now = DateTime.now();
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    final startDate = DateTime(fyStartYear, 4, 1);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + profile button
          Row(
            children: [
              // App logo
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/billcube_icon.jpeg',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting${firstName.isNotEmpty ? ', $firstName' : ''}!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(startDate)} – ${dateFormat.format(now)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              _bannerButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                outlined: true,
                isLoading: isRefreshing,
                onTap: isRefreshing
                    ? () {}
                    : () => context.read<DashboardProvider>().loadSummary(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bannerButton(
                  label: '+ New Invoice',
                  outlined: false,
                  onTap: () => context.push('/sales'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerButton({
    required String label,
    IconData? icon,
    required bool outlined,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: outlined ? null : AppColors.primaryGradient,
          color: outlined ? Colors.white : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: outlined ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: outlined ? AppColors.primary : Colors.white,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: outlined ? AppColors.primary : Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: outlined ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  // ─── Loading Shimmer ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _shimmerBox(height: 130, borderRadius: 18),
          ),
          const SizedBox(height: 16),
          // KPI scroll
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _shimmerBox(
                  height: 140, width: 160, borderRadius: 16),
            ),
          ),
          const SizedBox(height: 16),
          // Stats strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 80, borderRadius: 14),
          ),
          const SizedBox(height: 20),
          // Quick access
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 180, borderRadius: 16),
          ),
          const SizedBox(height: 20),
          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _shimmerBox(height: 100, borderRadius: 14)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(height: 100, borderRadius: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 100, borderRadius: 14),
          ),
          const SizedBox(height: 20),
          // Charts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 280, borderRadius: 12),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 280, borderRadius: 12),
          ),
          const SizedBox(height: 20),
          // Invoices
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 80, borderRadius: 12),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _shimmerBox(height: 80, borderRadius: 12),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double borderRadius = 12,
  }) {
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
        width: width ?? double.infinity,
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
