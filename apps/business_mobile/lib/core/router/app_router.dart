import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_copilot/presentation/ai_copilot_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/business/presentation/business_page.dart';
import '../../features/business_setup/presentation/business_setup_page.dart';
import '../../features/customers/presentation/customers_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/employees/presentation/employees_page.dart';
import '../../features/finance/presentation/finance_page.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/invoices/presentation/invoices_page.dart';
import '../../features/legal/presentation/legal_page.dart';
import '../../features/legal/presentation/legal_registration_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/payments/presentation/payments_page.dart';
import '../../features/products/presentation/products_page.dart';
import '../../features/promotions/presentation/promotions_page.dart';
import '../../features/purchases/presentation/purchases_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/sales/presentation/sales_page.dart';
import '../../features/services/presentation/services_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/suppliers/presentation/suppliers_page.dart';
import '../config/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    routes: [
      // ============================================================
      // AUTH
      // ============================================================
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // ============================================================
      // CORE
      // ============================================================
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      GoRoute(
        path: '/business-setup',
        builder: (context, state) => const BusinessSetupPage(),
      ),

      // ============================================================
      // BUSINESS
      // ============================================================
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessPage(),
      ),

      GoRoute(path: '/legal', builder: (context, state) => const LegalPage()),

      GoRoute(
        path: '/legal/registration',
        builder: (context, state) => const LegalRegistrationPage(),
      ),

      // ============================================================
      // AI
      // ============================================================
      GoRoute(
        path: '/ai-copilot',
        builder: (context, state) => const AiCopilotPage(),
      ),

      // ============================================================
      // CRM / PEOPLE
      // ============================================================
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersPage(),
      ),

      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeesPage(),
      ),

      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SuppliersPage(),
      ),

      // ============================================================
      // OPERATIONS
      // ============================================================
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryPage(),
      ),

      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsPage(),
      ),

      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesPage(),
      ),

      GoRoute(
        path: '/purchases',
        builder: (context, state) => const PurchasesPage(),
      ),

      GoRoute(path: '/sales', builder: (context, state) => const SalesPage()),

      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesPage(),
      ),

      // ============================================================
      // FINANCE
      // ============================================================
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinancePage(),
      ),

      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsPage(),
      ),

      // ============================================================
      // GROWTH
      // ============================================================
      GoRoute(
        path: '/promotions',
        builder: (context, state) => const PromotionsPage(),
      ),

      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),

      // ============================================================
      // SYSTEM
      // ============================================================
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],

    // ==============================================================
    // AUTH GUARD
    // ==============================================================
    redirect: (context, state) async {
      final loggedIn = await ref.read(authStateProvider.future);

      final location = state.matchedLocation;
      final isLogin = location == '/login';

      if (!loggedIn && !isLogin) {
        return '/login';
      }

      if (loggedIn && isLogin) {
        return '/dashboard';
      }

      return null;
    },
  );
});
