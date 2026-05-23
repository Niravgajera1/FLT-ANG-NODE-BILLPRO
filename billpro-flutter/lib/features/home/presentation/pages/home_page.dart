import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                        Text(
                          'Welcome to',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BillPro 🚀',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push('/profile');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 20, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Success Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 56, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Phase 1 Complete!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Authentication is working.\nYou are logged in successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ...[
                  (Icons.receipt_long_rounded, 'Sales Invoices', 'Create and manage bills', const Color(0xFFD97706), '/sales'),
                  (Icons.shopping_cart_rounded, 'Purchase Bills', 'Manage vendor purchases', const Color(0xFF0284C7), '/purchases'),
                  (Icons.people_alt_rounded, 'Customer Directory', 'Manage customer accounts', AppColors.primary, '/customers'),
                  (Icons.local_shipping_rounded, 'Vendor Directory', 'Manage vendor accounts', const Color(0xFFE11D48), '/vendors'),
                  (Icons.inventory_2_rounded, 'Product Catalogue', 'Products, services & inventory', const Color(0xFF059669), '/items'),
                  (Icons.business_rounded, 'Company Profile', 'GSTIN, branches, bank accounts', const Color(0xFF7C3AED), '/profile'),
                ].map((item) => Padding(

                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push(item.$5),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: item.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(item.$1, color: item.$4, size: 24)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                          Text(item.$3, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ])),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      ]),
                    ),
                  ),
                )),
              ],

            ),
          ),
        ),
    );
  }
}
