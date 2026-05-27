import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/login_otp_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/customer/presentation/pages/customer_list_page.dart';
import 'features/item/presentation/pages/item_list_page.dart';
import 'features/sales/presentation/pages/sales_list_page.dart';
import 'features/vendor/presentation/pages/vendor_list_page.dart';
import 'features/purchase/presentation/pages/purchase_list_page.dart';

class BillProApp extends StatelessWidget {
  const BillProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.isAuthenticated;
        final loc = state.matchedLocation;
        final publicRoutes = ['/', '/login', '/register', '/otp', '/forgot-password', '/reset-password', '/login-otp'];
        final isPublic = publicRoutes.contains(loc);

        if (isAuth && isPublic && loc != '/') return '/home';
        if (!isAuth && !isPublic && auth.status != AuthStatus.loading && auth.status != AuthStatus.initial) {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return OtpPage(
              identifier: extra['identifier']?.toString() ?? '',
              purpose: extra['purpose']?.toString() ?? 'email_verify',
            );
          },
        ),
        GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
        GoRoute(path: '/login-otp', builder: (context, state) => const LoginOtpPage()),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ResetPasswordPage(token: extra['token']?.toString() ?? '');
          },
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(path: '/customers', builder: (context, state) => const CustomerListPage()),
        GoRoute(path: '/items', builder: (context, state) => const ItemListPage()),
        GoRoute(path: '/sales', builder: (context, state) => const SalesListPage()),
        GoRoute(path: '/vendors', builder: (context, state) => const VendorListPage()),
        GoRoute(path: '/purchases', builder: (context, state) => const PurchaseListPage()),
      ],
    );

    return MaterialApp.router(
      title: 'BillCube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
